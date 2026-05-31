# frozen_string_literal: true

module Motor
  class EncryptedConfig
    # 文件存储配置校验器，隔离 S3 和 Google Cloud Storage 的字段规则。
    class StorageValidator
      REQUIRED_FIELDS = {
        'aws_s3' => %w[access_key_id secret_access_key region bucket],
        'google' => %w[credentials project bucket]
      }.freeze
      SERVICES = REQUIRED_FIELDS.keys.freeze

      # 保存被校验的加密配置记录。
      def initialize(record)
        @record = record
      end

      # 校验服务名、configs 结构和具体服务所需字段。
      def validate
        config = storage_value
        service = storage_service(config)
        configs = storage_configs(config)

        validate_storage_service_name(service)
        validate_storage_configs_presence(configs)

        return unless SERVICES.include?(service) && configs.is_a?(Hash)

        validate_storage_service_configs(service, configs.with_indifferent_access)
      end

      private

      attr_reader :record

      delegate :errors, :value, to: :record

      # 将 value 转成 indifferent access Hash，非 Hash 值按空配置处理。
      def storage_value
        value.respond_to?(:to_h) ? value.to_h.with_indifferent_access : {}
      end

      # 读取存储服务名称。
      def storage_service(config)
        config[:service].to_s
      end

      # 读取服务配置 Hash。
      def storage_configs(config)
        config[:configs]
      end

      # 校验服务名存在且属于支持列表。
      def validate_storage_service_name(service)
        errors.add(:value, 'must include service') if service.blank?
        errors.add(:value, 'must use supported storage service') if service.present? && SERVICES.exclude?(service)
      end

      # 校验 configs 节点必须是 Hash。
      def validate_storage_configs_presence(configs)
        errors.add(:value, 'must include configs') unless configs.is_a?(Hash)
      end

      # 校验指定服务的必填字段，并额外检查 GCS credentials JSON。
      def validate_storage_service_configs(service, configs)
        missing_fields = REQUIRED_FIELDS.fetch(service).select { |field| configs[field].blank? }

        errors.add(:value, "storage configs must include #{missing_fields.join(', ')}") if missing_fields.any?

        validate_google_credentials_json(configs[:credentials]) if service == 'google' && configs[:credentials].present?
      end

      # 校验 Google credentials 可作为 JSON 解析，Hash 值直接视为合法。
      def validate_google_credentials_json(credentials)
        return if credentials.is_a?(Hash)

        JSON.parse(credentials)
      rescue JSON::ParserError, TypeError
        errors.add(:value, 'google credentials must be valid JSON')
      end
    end
  end
end
