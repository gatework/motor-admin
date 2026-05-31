# frozen_string_literal: true

module Motor
  # 管理后台加密配置，保存数据库、邮件、存储等敏感设置。
  class EncryptedConfig < ::Motor::ApplicationRecord
    encrypts :value

    serialize :value, coder: Motor::HashSerializer

    DATABASE_CREDENTIALS_KEY = 'database.credentials'
    SLACK_CREDENTIALS_KEY = 'slack.credentials'
    EMAIL_SMTP_KEY = 'email.smtp'
    FILES_STORAGE_KEY = 'files.storage'

    KNOWN_KEYS = [DATABASE_CREDENTIALS_KEY, SLACK_CREDENTIALS_KEY, EMAIL_SMTP_KEY, FILES_STORAGE_KEY].freeze

    validates :key, presence: true, uniqueness: true, inclusion: { in: KNOWN_KEYS }

    validate :value_matches_known_key

    # 判断 key 是否属于系统支持的加密配置项。
    def self.known_key?(key)
      KNOWN_KEYS.include?(key.to_s)
    end

    private

    # 根据配置 key 分派到对应 value 校验逻辑。
    def value_matches_known_key
      return if key.blank?

      case key
      when DATABASE_CREDENTIALS_KEY
        validate_database_credentials
      when EMAIL_SMTP_KEY
        validate_hash_fields(%w[address host port username password])
      when FILES_STORAGE_KEY
        validate_storage_config
      when SLACK_CREDENTIALS_KEY
        validate_hash_fields(%w[api_key])
      end
    end

    # 校验数据库连接配置数组的结构、URL、重名和 schema_search_path。
    def validate_database_credentials
      return errors.add(:value, 'must be an array') unless value.is_a?(Array)

      entries = database_config_entries

      validate_database_config_required_fields(entries)
      validate_database_config_duplicate_names(entries)
      validate_database_config_url_schemes(entries)
      validate_database_config_schema_search_paths(entries)
    end

    # 将数据库配置数组中的可哈希项转成 indifferent access Hash。
    def database_config_entries
      value.map do |entry|
        entry = entry.to_h.with_indifferent_access if entry.respond_to?(:to_h)

        entry if entry.is_a?(Hash)
      end
    end

    # 判断单条数据库配置是否缺少 name 或 url。
    def invalid_database_config_entry?(entry)
      entry.blank? ||
        Motor::DatabaseConfigs.normalize_name(entry[:name]).blank? ||
        entry[:url].blank?
    end

    # 为缺少必填字段的数据库配置添加错误。
    def validate_database_config_required_fields(entries)
      return unless entries.any? { |entry| invalid_database_config_entry?(entry) }

      errors.add(:value, 'database configs must include name and url')
    end

    # 判断数据库 URL 是否存在但不是支持的格式。
    def unsupported_database_config_url?(entry)
      entry.present? &&
        entry[:url].present? &&
        !Motor::DatabaseConfigs.valid_database_url?(entry[:url])
    end

    # 校验所有数据库配置 URL scheme。
    def validate_database_config_url_schemes(entries)
      return unless entries.any? { |entry| unsupported_database_config_url?(entry) }

      errors.add(:value, Motor::DatabaseConfigs::UNSUPPORTED_DATABASE_URL_MESSAGE)
    end

    # 判断规范化后的连接类名是否重复。
    def duplicate_database_config_names?(entries)
      class_names =
        entries.filter_map do |entry|
          next if entry.blank? || Motor::DatabaseConfigs.normalize_name(entry[:name]).blank?

          Motor::DatabaseConfigs.connection_class_name(entry[:name])
        end

      class_names.size != class_names.uniq.size
    end

    # 拒绝会映射到同一个动态连接类名的数据库配置。
    def validate_database_config_duplicate_names(entries)
      return unless duplicate_database_config_names?(entries)

      errors.add(:value, Motor::DatabaseConfigs::DUPLICATE_DATABASE_NAME_MESSAGE)
    end

    # 判断 PostgreSQL schema_search_path 是否存在但格式不安全。
    def unsafe_database_schema_search_path?(entry)
      entry.present? &&
        entry[:schema_search_path].present? &&
        !Motor::DatabaseConfigs.valid_schema_search_path?(entry[:schema_search_path])
    end

    # 校验所有数据库配置的 schema_search_path。
    def validate_database_config_schema_search_paths(entries)
      return unless entries.any? { |entry| unsafe_database_schema_search_path?(entry) }

      errors.add(:value, Motor::DatabaseConfigs::INVALID_SCHEMA_SEARCH_PATH_MESSAGE)
    end

    # 校验 Hash 类型配置是否包含指定字段。
    def validate_hash_fields(required_fields)
      missing_fields = required_fields.select { |field| value_for(field).blank? }

      errors.add(:value, "must include #{missing_fields.join(', ')}") if missing_fields.any?
    end

    # 委托存储配置校验器处理 S3/GCS 细节。
    def validate_storage_config
      StorageValidator.new(self).validate
    end

    # 从配置 value 中按 indifferent key 读取字段。
    def value_for(field)
      return unless value.respond_to?(:to_h)

      value.to_h.with_indifferent_access[field]
    end
  end
end
