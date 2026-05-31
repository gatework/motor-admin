# frozen_string_literal: true

require 'test_helper'

module Api
  class EncryptedConfigsTest < ActionDispatch::IntegrationTest
    setup do
      @actor = create_admin_user(roles: [Motor::Role.superadmin])

      sign_in @actor, scope: :admin_user
    end

    test 'stores database credentials with permitted fields only' do
      post '/admin/api/encrypted_configs',
           params: {
             data: {
               key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
               value: [
                 {
                   name: 'primary',
                   url: 'postgres://localhost/app',
                   schema_search_path: 'public',
                   ignored: 'remove-me'
                 }
               ]
             }
           },
           as: :json

      assert_response :success

      value = json_response.dig('data', 'value')

      assert_equal(
        [{ 'name' => 'primary', 'url' => 'postgres://localhost/app', 'schema_search_path' => 'public' }],
        value
      )
    end

    test 'updates existing encrypted config' do
      Motor::EncryptedConfig.create!(
        key: Motor::EncryptedConfig::SLACK_CREDENTIALS_KEY,
        value: { api_key: 'old' }
      )

      post '/admin/api/encrypted_configs',
           params: {
             data: {
               key: Motor::EncryptedConfig::SLACK_CREDENTIALS_KEY,
               value: { api_key: 'new', ignored: 'remove-me' }
             }
           },
           as: :json

      assert_response :success
      assert_equal({ 'api_key' => 'new' }, Motor::EncryptedConfig.find_by!(key: 'slack.credentials').value)
    end

    test 'returns nil for missing known config' do
      get "/admin/api/encrypted_configs/#{Motor::EncryptedConfig::EMAIL_SMTP_KEY}", as: :json

      assert_response :success
      assert_nil json_response.dig('data', 'value')
    end
  end
end
