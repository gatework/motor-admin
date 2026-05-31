# frozen_string_literal: true

require 'test_helper'

module Api
  class EncryptedConfigVisibilityTest < ActionDispatch::IntegrationTest
    setup do
      @actor = create_admin_user(roles: [Motor::Role.superadmin])

      sign_in @actor, scope: :admin_user
    end

    test 'returns raw encrypted config values for manager' do
      create_email_config(password: 'secret')

      get "/admin/api/encrypted_configs/#{Motor::EncryptedConfig::EMAIL_SMTP_KEY}", as: :json

      assert_response :success
      assert_equal 'secret', json_response.dig('data', 'value', 'password')
    end

    test 'masks encrypted config values for read only user' do
      create_email_config(password: 'secret')
      sign_out @actor

      reader = create_admin_user(
        email: 'encrypted-reader@example.com',
        roles: [encrypted_config_reader_role]
      )

      sign_in reader, scope: :admin_user

      get "/admin/api/encrypted_configs/#{Motor::EncryptedConfig::EMAIL_SMTP_KEY}", as: :json

      assert_response :success
      assert_equal '[FILTERED]', json_response.dig('data', 'value', 'password')
      assert_equal 'smtp.example.com', json_response.dig('data', 'value', 'host')
    end

    private

    # 构造只能读取加密配置但不能管理明文值的角色。
    def encrypted_config_reader_role
      create_role(
        name: 'encrypted-config-reader',
        rules: [{ subjects: ['Motor::EncryptedConfig'], actions: ['read'] }]
      )
    end

    # 创建邮件加密配置，用于验证脱敏输出。
    def create_email_config(password:)
      Motor::EncryptedConfig.create!(
        key: Motor::EncryptedConfig::EMAIL_SMTP_KEY,
        value: {
          address: 'admin@example.com',
          host: 'smtp.example.com',
          port: 587,
          username: 'admin',
          password: password
        }
      )
    end
  end
end
