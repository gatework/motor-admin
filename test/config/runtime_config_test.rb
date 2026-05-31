# frozen_string_literal: true

require 'test_helper'

module MotorAdmin
  class RuntimeConfigTest < ActiveSupport::TestCase
    test 'normalizes base path' do
      assert_equal '/admin', RuntimeConfig.normalize_base_path(nil)
      assert_equal '/admin', RuntimeConfig.normalize_base_path('')
      assert_equal '/admin', RuntimeConfig.normalize_base_path('admin/')
      assert_equal '/admin', RuntimeConfig.normalize_base_path('//admin//')
      assert_equal '/', RuntimeConfig.normalize_base_path('/')
    end

    test 'reads normalized base path from environment' do
      with_env('BASE_PATH' => 'internal/admin/') do
        assert_equal '/internal/admin', RuntimeConfig.base_path
      end
    end

    test 'detects enabled ssl flags' do
      with_env('FORCE_SSL' => 'yes', 'MOTOR_FORCE_SSL' => nil, 'SSL_KEY_PATH' => nil) do
        assert_equal true, RuntimeConfig.force_ssl?
      end

      with_env('FORCE_SSL' => nil, 'MOTOR_FORCE_SSL' => nil, 'SSL_KEY_PATH' => '/tmp/server.key') do
        assert_equal true, RuntimeConfig.force_ssl?
      end

      with_env('FORCE_SSL' => nil, 'MOTOR_FORCE_SSL' => nil, 'SSL_KEY_PATH' => nil) do
        assert_equal false, RuntimeConfig.force_ssl?
      end
    end

    test 'builds default url options when host is configured' do
      with_env('HOST' => 'example.test', 'PORT' => '443') do
        assert_equal(
          { protocol: 'https', host: 'example.test' },
          RuntimeConfig.default_url_options(force_ssl: true)
        )
      end

      with_env('HOST' => 'example.test', 'PORT' => '3000') do
        assert_equal(
          { protocol: 'http', host: 'example.test', port: '3000' },
          RuntimeConfig.default_url_options(force_ssl: false)
        )
      end

      with_env('HOST' => '', 'PORT' => '3000') do
        assert_equal({}, RuntimeConfig.default_url_options(force_ssl: false))
      end
    end

    test 'derives active record encryption config from secret key base' do
      secret = 'a' * 64

      with_env('SECRET_KEY_BASE' => secret) do
        assert_equal(
          {
            primary_key: 'a' * 32,
            deterministic_key: 'a' * 32,
            key_derivation_salt: secret
          },
          RuntimeConfig.active_record_encryption_config
        )
      end
    end

    private

    # 临时设置环境变量并在测试结束后恢复。
    def with_env(values)
      previous_values = values.keys.index_with { |key| ENV[key] }

      values.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end

      yield
    ensure
      previous_values.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end
    end
  end
end
