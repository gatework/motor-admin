# frozen_string_literal: true

require 'test_helper'

module Api
  class EncryptedConfigValidationTest < ActionDispatch::IntegrationTest
    setup do
      sign_in create_admin_user(roles: [Motor::Role.superadmin]), scope: :admin_user
    end

    test 'rejects unknown config key' do
      post '/admin/api/encrypted_configs',
           params: { data: { key: 'unknown.secret', value: { token: 'hidden' } } },
           as: :json

      assert_response :unprocessable_content
      assert_includes json_response.dig('errors', 'key'), 'is not included in the list'
    end

    test 'rejects invalid database config value' do
      post '/admin/api/encrypted_configs',
           params: {
             data: {
               key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
               value: [{ name: 'primary' }]
             }
           },
           as: :json

      assert_response :unprocessable_content
      assert_includes json_response.dig('errors', 'value'), 'database configs must include name and url'
    end

    test 'rejects unsafe database schema search path' do
      post '/admin/api/encrypted_configs',
           params: {
             data: {
               key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
               value: [
                 {
                   name: 'primary',
                   url: 'postgres://localhost/app',
                   schema_search_path: 'public;DROP SCHEMA public'
                 }
               ]
             }
           },
           as: :json

      assert_response :unprocessable_content
      assert_includes(
        json_response.dig('errors', 'value'),
        Motor::DatabaseConfigs::INVALID_SCHEMA_SEARCH_PATH_MESSAGE
      )
    end

    test 'rejects invalid storage config value' do
      post '/admin/api/encrypted_configs',
           params: {
             data: {
               key: Motor::EncryptedConfig::FILES_STORAGE_KEY,
               value: {
                 service: 'aws_s3',
                 configs: { access_key_id: 'access-key' }
               }
             }
           },
           as: :json

      assert_response :unprocessable_content
      assert_includes(
        json_response.dig('errors', 'value'),
        'storage configs must include secret_access_key, region, bucket'
      )
    end
  end
end
