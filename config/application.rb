# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_cable/engine'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MotorAdmin
  module RuntimeConfig
    TRUE_VALUES = %w[1 on t true y yes].freeze
    DEFAULT_BASE_PATH = '/admin'

    module_function

    # 返回规范化后的后台挂载路径。
    def base_path
      normalize_base_path(ENV.fetch('BASE_PATH', DEFAULT_BASE_PATH))
    end

    # 规范化 base_path，确保以 / 开头且不保留多余尾斜杠。
    def normalize_base_path(path)
      path = path.to_s.strip
      path = DEFAULT_BASE_PATH if path.empty?
      path = "/#{path}" unless path.start_with?('/')
      path = path.squeeze('/')
      path = path.delete_suffix('/') unless path == '/'
      path
    end

    # 判断是否应强制 HTTPS，支持 FORCE_SSL/MOTOR_FORCE_SSL 和证书路径触发。
    def force_ssl?
      env_true?('FORCE_SSL', 'MOTOR_FORCE_SSL') || ENV['SSL_KEY_PATH'].to_s.strip.present?
    end

    # 根据 HOST/PORT/SSL 配置生成 Rails URL helper 默认选项。
    def default_url_options(force_ssl:)
      host = ENV['HOST'].to_s.strip

      return {} if host.blank?

      {
        protocol: force_ssl ? 'https' : 'http',
        host: host,
        port: default_url_port
      }.compact
    end

    # 读取生产环境必需的 SECRET_KEY_BASE。
    def secret_key_base
      ENV.fetch('SECRET_KEY_BASE')
    end

    # 从 SECRET_KEY_BASE 派生 Active Record Encryption 配置。
    def active_record_encryption_config
      secret = secret_key_base

      {
        primary_key: secret[0, 32].to_s,
        deterministic_key: secret[32, 32].to_s,
        key_derivation_salt: secret
      }
    end

    # 判断任一环境变量是否为常见 truthy 值。
    def env_true?(*keys)
      keys.any? { |key| TRUE_VALUES.include?(ENV[key].to_s.strip.downcase) }
    end

    # 返回非标准 HTTP/HTTPS 端口，默认端口不写入 URL。
    def default_url_port
      port = ENV['PORT'].to_s.strip

      return if port.blank? || %w[80 443].include?(port)

      port
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    if ENV['RAILS_ENV'] == 'production'
      motor_admin_spec = Gem.loaded_specs.fetch('motor-admin-pro') { Gem.loaded_specs.fetch('motor-admin') }

      config.eager_load_paths << "#{motor_admin_spec.full_gem_path}/app/controllers/concerns"
      config.eager_load_paths << "#{Gem.loaded_specs['activestorage'].full_gem_path}/app/controllers/concerns"
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
