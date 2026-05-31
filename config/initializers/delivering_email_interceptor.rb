# frozen_string_literal: true

# 动态邮件设置拦截器，在发信前应用后台保存的 SMTP 配置。
module DynamicSettingsInterceptor
  module_function

  # 发信前读取后台 SMTP 配置并覆盖当前邮件的 delivery_method。
  def delivering_email(message)
    email_configs = Motor::EncryptedConfig.find_by(key: Motor::EncryptedConfig::EMAIL_SMTP_KEY)

    return message unless email_configs&.valid?

    settings = smtp_settings(email_configs.value)

    message.delivery_method(:smtp, settings.except(:from_address).compact)
    message.from = settings[:from_address] if settings[:from_address].present?
    message.reply_to = settings[:from_address] if settings[:from_address].present?

    message
  end

  # 将加密配置中的邮件字段映射为 ActionMailer SMTP 设置。
  def smtp_settings(value)
    value = value.to_h.with_indifferent_access

    {
      user_name: value[:username],
      password: value[:password],
      address: value[:host],
      port: value[:port],
      tls: value[:port].to_s == '465',
      from_address: value[:address]
    }
  end
end

ActionMailer::Base.register_interceptor(DynamicSettingsInterceptor)
