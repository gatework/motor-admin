# frozen_string_literal: true

module Motor
  # 加密配置序列化器，根据当前权限决定是否隐藏敏感字段。
  class EncryptedConfigSerializer
    FILTERED_VALUE = '[FILTERED]'
    SENSITIVE_VALUE_KEYS = %w[access_key_id api_key credentials password secret_access_key url].freeze

    # 保存权限对象，用于判断是否可查看敏感配置。
    def initialize(ability)
      @ability = ability
    end

    # 输出前端需要的 key/value 结构。
    def as_json(config)
      {
        key: config.key,
        value: serialized_value(config.value)
      }
    end

    private

    attr_reader :ability

    # 根据权限决定返回原值还是脱敏值。
    def serialized_value(value)
      expose_sensitive_config_values? ? value : mask_sensitive_value(value)
    end

    # 拥有管理加密配置权限的用户可以查看明文配置。
    def expose_sensitive_config_values?
      ability.can?(:manage, Motor::EncryptedConfig)
    end

    # 递归脱敏敏感字段，保留非敏感结构便于前端编辑。
    def mask_sensitive_value(value, key = nil)
      if key.present? && SENSITIVE_VALUE_KEYS.include?(key.to_s) && value.present?
        FILTERED_VALUE
      elsif value.is_a?(Hash)
        value.each_with_object({}) do |(child_key, child_value), acc|
          acc[child_key] = mask_sensitive_value(child_value, child_key)
        end
      elsif value.is_a?(Array)
        value.map { |item| mask_sensitive_value(item) }
      else
        value
      end
    end
  end
end
