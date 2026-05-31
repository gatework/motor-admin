# frozen_string_literal: true

require 'test_helper'

module Motor
  class DatabaseConfigsTest < ActiveSupport::TestCase
    test 'normalizes database urls' do
      assert_equal 'mysql2://localhost/app', Motor::DatabaseConfigs.normalize_url('mysql://localhost/app')
      assert_equal 'mysql2://localhost/app', Motor::DatabaseConfigs.normalize_url(' MYSQL://localhost/app ')
      assert_equal 'postgres://localhost/app', Motor::DatabaseConfigs.normalize_url('postgresql://localhost/app')
      assert_equal 'postgres://localhost/app', Motor::DatabaseConfigs.normalize_url('PostgreSQL://localhost/app')
      assert_equal 'postgres://localhost/app', Motor::DatabaseConfigs.normalize_url('postgres://localhost/app')
      assert_equal 'sqlserver://localhost/app', Motor::DatabaseConfigs.normalize_url('SQLSERVER://localhost/app')
      assert_nil Motor::DatabaseConfigs.normalize_url('ftp://localhost/app')
      assert_nil Motor::DatabaseConfigs.normalize_url('postgres:localhost/app')
    end

    test 'detects supported database urls' do
      assert Motor::DatabaseConfigs.supported_database_url?('postgres://localhost/app')
      assert_not Motor::DatabaseConfigs.supported_database_url?('ftp://localhost/app')
      assert_not Motor::DatabaseConfigs.supported_database_url?('postgres:localhost/app')
    end

    test 'detects valid database urls' do
      assert Motor::DatabaseConfigs.valid_database_url?('postgres://localhost/app?sslmode=disable')
      assert_not Motor::DatabaseConfigs.valid_database_url?('ftp://localhost/app')
      assert_not Motor::DatabaseConfigs.valid_database_url?('postgres:localhost/app')
      assert_not Motor::DatabaseConfigs.valid_database_url?('postgres://localhost/app?sslmode=%')
    end

    test 'normalizes database names' do
      assert_equal 'primary', Motor::DatabaseConfigs.normalize_name(' primary ')
      assert_nil Motor::DatabaseConfigs.normalize_name(' ')
    end

    test 'builds connection class names compatible with motor query lookup' do
      assert_equal 'Default', Motor::DatabaseConfigs.connection_class_name(' default ')
      assert_equal 'ReportsDb', Motor::DatabaseConfigs.connection_class_name('123 reports-db')
      assert_equal 'Database', Motor::DatabaseConfigs.connection_class_name('123')
    end

    test 'normalizes safe schema search paths' do
      assert_equal 'public,tenant_a', Motor::DatabaseConfigs.normalize_schema_search_path(' public, tenant_a ')
      assert_nil Motor::DatabaseConfigs.normalize_schema_search_path('public;DROP SCHEMA public')
      assert_nil Motor::DatabaseConfigs.normalize_schema_search_path('"$user", public')
    end

    test 'normalizes saved database entries' do
      entries = Motor::DatabaseConfigs.normalized_entries(
        [
          { name: 'primary', url: 'postgresql://localhost/app', schema_search_path: 'public' },
          { name: ' legacy ', url: ' mysql://localhost/app ' },
          { name: 'missing-url' },
          { url: 'postgres://localhost/missing_name' }
        ]
      )

      assert_equal(
        [
          { 'name' => 'primary', 'url' => 'postgres://localhost/app', 'schema_search_path' => 'public' },
          { 'name' => 'legacy', 'url' => 'mysql2://localhost/app' }
        ],
        entries
      )
    end

    test 'drops saved database entries with unsafe schema search paths' do
      entries = Motor::DatabaseConfigs.normalized_entries(
        [
          { name: 'primary', url: 'postgresql://localhost/app', schema_search_path: 'public;DROP SCHEMA public' },
          { name: 'tenant', url: 'postgresql://localhost/app', schema_search_path: 'tenant_a' }
        ]
      )

      assert_equal(
        [{ 'name' => 'tenant', 'url' => 'postgres://localhost/app', 'schema_search_path' => 'tenant_a' }],
        entries
      )
    end

    test 'loads normalized configured entries' do
      Motor::EncryptedConfig.create!(
        key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
        value: [{ name: 'primary', url: 'postgresql://localhost/app' }]
      )

      assert_equal(
        [{ 'name' => 'primary', 'url' => 'postgres://localhost/app' }],
        Motor::DatabaseConfigs.configured_entries
      )
    end
  end

  class DatabaseConfigConnectionsTest < ActiveSupport::TestCase
    test 'connection signature includes url and schema search path' do
      signature = Motor::DatabaseConfigs.connection_signature(
        'url' => 'postgres://localhost/app',
        'schema_search_path' => 'tenant_a'
      )

      assert_equal ['postgres://localhost/app', 'tenant_a'], signature
    end

    test 'schema search path safely skips unsupported connections' do
      base_class = Class.new do
        # 返回不支持 schema_search_path 的假连接。
        def self.connection
          Object.new
        end
      end

      assert_nil Motor::DatabaseConfigs.apply_schema_search_path(base_class, 'tenant_a')
    end

    test 'schema search path is applied when supported' do
      connection = Class.new do
        attr_accessor :schema_search_path
        attr_reader :schema_cache

        # 初始化带 schema cache 的假 PostgreSQL 连接。
        def initialize
          @schema_search_path = 'public'
          @schema_cache = Class.new do
            attr_reader :cleared

            # 标记 schema cache 已被清理。
            def clear!
              @cleared = true
            end
          end.new
        end
      end.new

      base_class = Class.new do
        define_singleton_method(:connection) { connection }
      end

      Motor::DatabaseConfigs.apply_schema_search_path(base_class, 'tenant_a')

      assert_equal 'tenant_a', connection.schema_search_path
      assert connection.schema_cache.cleared
    end

    test 'unsafe schema search path is ignored when applying' do
      connection = Class.new do
        attr_accessor :schema_search_path

        # 初始化仅支持读取 schema_search_path 的假连接。
        def initialize
          @schema_search_path = 'public'
        end
      end.new

      base_class = Class.new do
        define_singleton_method(:connection) { connection }
      end

      Motor::DatabaseConfigs.apply_schema_search_path(base_class, 'public;DROP SCHEMA public')

      assert_equal 'public', connection.schema_search_path
    end
  end
end
