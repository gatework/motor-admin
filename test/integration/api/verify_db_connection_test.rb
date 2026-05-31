# frozen_string_literal: true

require 'test_helper'

module Api
  class VerifyDbConnectionTest < ActionDispatch::IntegrationTest
    setup { sign_in create_admin_user(roles: [Motor::Role.superadmin]), scope: :admin_user }

    test 'rejects unsupported database url' do
      post '/admin/api/verify_db_connection', params: { url: 'sqlite3://tmp/app.sqlite3' }, as: :json

      assert_response :unprocessable_content
      assert_equal ['Database URL is invalid'], json_response['errors']
    end

    test 'rejects incomplete database url' do
      post '/admin/api/verify_db_connection', params: { url: 'postgres:localhost/app' }, as: :json

      assert_response :unprocessable_content
      assert_equal ['Database URL is invalid'], json_response['errors']
    end

    test 'rejects missing database url' do
      post '/admin/api/verify_db_connection', params: {}, as: :json

      assert_response :bad_request
      assert_match(/param is missing/, json_response['errors'].first)
    end

    test 'rejects malformed encoded database url' do
      post '/admin/api/verify_db_connection', params: { url: 'postgres://localhost/app?sslmode=%' }, as: :json

      assert_response :unprocessable_content
      assert_equal ['Database URL is invalid'], json_response['errors']
    end

    test 'rejects unsafe schema search path before connecting' do
      post '/admin/api/verify_db_connection',
           params: {
             url: 'postgres://localhost/app',
             schema_search_path: 'public;DROP SCHEMA public'
           },
           as: :json

      assert_response :unprocessable_content
      assert_equal [Motor::DatabaseConfigs::INVALID_SCHEMA_SEARCH_PATH_MESSAGE], json_response['errors']
    end

    test 'sets postgres connection timeout when verifying' do
      captured_url = nil
      connection = fake_connection

      with_stubbed_singleton_method(PG, :connect, lambda { |url|
        captured_url = url
        connection
      }) do
        post '/admin/api/verify_db_connection',
             params: {
               url: 'postgres://localhost/app?sslmode=disable&connect_timeout=60',
               schema_search_path: 'public'
             },
             as: :json
      end

      assert_response :ok
      assert_includes query_values(captured_url), %w[sslmode disable]
      assert_includes query_values(captured_url), %w[connect_timeout 5]
      assert_not_includes query_values(captured_url), %w[connect_timeout 60]
      assert_predicate connection, :closed?
    end

    test 'sets mysql timeouts and decodes credentials when verifying' do
      captured_options = nil
      connection = fake_connection

      with_stubbed_singleton_method(Mysql2::Client, :new, lambda { |options|
        captured_options = options
        connection
      }) do
        post '/admin/api/verify_db_connection',
             params: { url: 'mysql2://user%40example.com:p%40ss@localhost:3306/app%20db' },
             as: :json
      end

      assert_response :ok
      assert_equal 'user@example.com', captured_options[:username]
      assert_equal 'p@ss', captured_options[:password]
      assert_equal 'app db', captured_options[:database]
      assert_equal 5, captured_options[:connect_timeout]
      assert_equal 5, captured_options[:read_timeout]
      assert_equal 5, captured_options[:write_timeout]
      assert_predicate connection, :closed?
    end

    test 'normalizes url scheme and keeps literal plus signs when verifying' do
      captured_options = nil
      connection = fake_connection

      with_stubbed_singleton_method(Mysql2::Client, :new, lambda { |options|
        captured_options = options
        connection
      }) do
        post '/admin/api/verify_db_connection',
             params: { url: ' MYSQL://user+tag:p%2Bss@localhost:3306/app+db ' },
             as: :json
      end

      assert_response :ok
      assert_equal 'user+tag', captured_options[:username]
      assert_equal 'p+ss', captured_options[:password]
      assert_equal 'app+db', captured_options[:database]
      assert_predicate connection, :closed?
    end

    private

    # 构造可记录关闭状态的假数据库连接。
    def fake_connection
      Class.new do
        # 标记连接已关闭。
        def close
          @closed = true
        end

        # 返回连接是否已关闭。
        def closed?
          @closed == true
        end
      end.new
    end

    # 解析 URL 查询参数为键值数组。
    def query_values(url) = URI.decode_www_form(URI.parse(url).query)
  end
end
