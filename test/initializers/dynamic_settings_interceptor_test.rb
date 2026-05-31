# frozen_string_literal: true

require 'test_helper'

class DynamicSettingsInterceptorTest < ActiveSupport::TestCase
  test 'leaves message unchanged without smtp config' do
    message = Mail.new(from: 'default@example.com', reply_to: 'reply@example.com')

    result = DynamicSettingsInterceptor.delivering_email(message)

    assert_same message, result
    assert_equal ['default@example.com'], message.from
    assert_equal ['reply@example.com'], message.reply_to
  end

  test 'applies smtp config before delivery' do
    Motor::EncryptedConfig.create!(
      key: Motor::EncryptedConfig::EMAIL_SMTP_KEY,
      value: {
        address: 'admin@example.com',
        host: 'smtp.example.com',
        port: 465,
        username: 'mailer',
        password: 'secret'
      }
    )
    message = Mail.new

    DynamicSettingsInterceptor.delivering_email(message)

    settings = message.delivery_method.settings

    assert_equal ['admin@example.com'], message.from
    assert_equal ['admin@example.com'], message.reply_to
    assert_equal 'smtp.example.com', settings[:address]
    assert_equal 465, settings[:port]
    assert_equal 'mailer', settings[:user_name]
    assert_equal 'secret', settings[:password]
    assert_equal true, settings[:tls]
    assert_not_includes settings.keys, :from_address
  end
end
