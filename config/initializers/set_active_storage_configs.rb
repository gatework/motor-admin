# frozen_string_literal: true

# 动态附件存储配置，在请求前把后台保存的存储配置同步到 Active Storage。
module SetActiveStorageConfigs
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_active_storage_configs
  end

  # 请求前读取后台文件存储配置并同步到 Active Storage。
  def set_active_storage_configs
    configs = Motor::EncryptedConfig.find_by(key: Motor::EncryptedConfig::FILES_STORAGE_KEY)

    return unless configs&.valid?

    apply_active_storage_config(configs.value)
  end

  private

  # 将存储服务和配置项写入 Rails active_storage.service_configurations。
  def apply_active_storage_config(config)
    config = config.to_h.with_indifferent_access
    service = config[:service].to_s
    service_config = active_storage_service_config(service)

    return unless service_config

    service_config.merge!(storage_service_options(service, config[:configs].to_h.with_indifferent_access))

    refresh_active_storage_service(service)
  end

  # 获取指定服务的 Active Storage 配置节点。
  def active_storage_service_config(service)
    Rails.application.config.active_storage.service_configurations[service]
  end

  # 归一化后台保存的存储配置，按服务补充 SDK 所需字段。
  def storage_service_options(service, configs)
    options = configs.dup

    options[:force_path_style] = true if options[:endpoint].present?
    options[:credentials] = google_credentials(options[:credentials]) if service == 'google'

    options
  end

  # Google credentials 支持 Hash 或 JSON 字符串两种输入。
  def google_credentials(credentials)
    return credentials if credentials.is_a?(Hash)

    JSON.parse(credentials.to_s)
  end

  # 刷新 Active Storage 当前服务实例，确保后续上传使用最新配置。
  def refresh_active_storage_service(service)
    active_storage = Rails.application.config.active_storage

    active_storage.service = service.to_sym

    ActiveStorage::Blob.services =
      ActiveStorage::Service::Registry.new(active_storage.service_configurations)

    ActiveStorage::Blob.service = ActiveStorage::Blob.services.fetch(active_storage.service)
  end
end

Rails.configuration.to_prepare do
  Motor::ApplicationController.include(SetActiveStorageConfigs)
  ApplicationController.include(SetActiveStorageConfigs)
end
