# frozen_string_literal: true

require 'motor/configs'

module Motor
  # 管理后台配置命令，负责本地 motor.yml 和远程配置的导入导出。
  module ConfigsCli
    class ConfigurationError < StandardError; end
    SYNC_REMOTE_URL_KEYS = %w[MOTOR_SYNC_REMOTE_URL SYNC_REMOTE_URL].freeze
    SYNC_API_KEY_KEYS = %w[MOTOR_SYNC_API_KEY SYNC_API_KEY].freeze

    module_function

    # 将当前数据库中的 Motor 配置导出到 motor.yml。
    def dump
      Motor::Configs::WriteToFile.write_with_lock

      puts '✅ motor.yml configs file has been updated'
    end

    # 从 motor.yml 导入配置到数据库。
    def load
      Motor::Configs::SyncFromFile.call(with_exception: true)

      puts '✅ configs have been loaded from motor.yml'
    end

    # 清空内存配置缓存后重新从 motor.yml 导入。
    def reload
      ActiveRecord::Base.transaction do
        Motor::Configs.clear
        Motor::Configs::SyncFromFile.call(with_exception: true)
      end

      puts '✅ configs have been re-loaded from motor.yml'
    end

    # 从远端应用同步配置后写回本地 motor.yml。
    def sync
      remote_url, api_key = sync_credentials

      Motor::Configs::SyncWithRemote.call(remote_url, api_key)
      Motor::Configs::WriteToFile.write_with_lock

      puts "✅ Motor Admin configurations have been synced with #{remote_url}"
    rescue Motor::Configs::SyncWithRemote::ApiNotFound
      puts '⚠️  Synchronization failed: you need to specify `MOTOR_SYNC_API_KEY` ' \
           'env variable in your remote app in order to enable this feature'
    end

    # 从环境变量读取远端同步地址和 API key。
    def sync_credentials
      remote_url = first_present_env(SYNC_REMOTE_URL_KEYS)
      api_key = first_present_env(SYNC_API_KEY_KEYS)

      validate_sync_credentials!(remote_url, api_key)

      [remote_url, api_key]
    end

    # 校验同步所需的远端地址和 API key 是否齐全。
    def validate_sync_credentials!(remote_url, api_key)
      if remote_url.blank?
        raise ConfigurationError,
              'Specify target app url using `MOTOR_SYNC_REMOTE_URL` or `SYNC_REMOTE_URL` env variable'
      end

      return if api_key.present?

      raise ConfigurationError, 'Specify sync api key using `MOTOR_SYNC_API_KEY` or `SYNC_API_KEY` env variable'
    end

    # 返回一组环境变量中第一个非空值。
    def first_present_env(keys)
      keys.lazy.map { |key| ENV[key].presence }.find(&:present?)
    end
  end
end
