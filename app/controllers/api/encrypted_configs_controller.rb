# frozen_string_literal: true

module Api
  # 管理后台加密配置 API，只允许维护系统识别的敏感配置项。
  class EncryptedConfigsController < ApiBaseController
    class UnknownConfigKey < StandardError; end

    DATABASE_CONFIG_FIELDS = %i[name url schema_search_path].freeze
    EMAIL_CONFIG_FIELDS = %i[address host port username password].freeze
    STORAGE_CONFIG_FIELDS = %i[
      access_key_id
      bucket
      credentials
      endpoint
      project
      region
      secret_access_key
    ].freeze

    wrap_parameters :data, except: %i[include fields]

    load_and_authorize_resource class: 'Motor::EncryptedConfig', id_param: :key, find_by: :key

    rescue_from ActiveRecord::RecordNotFound, with: :render_missing_encrypted_config
    rescue_from UnknownConfigKey, with: :render_unknown_config_key

    # 返回所有加密配置，敏感值根据权限自动脱敏。
    def index
      render json: { data: @encrypted_configs.map { |config| serialized_encrypted_config(config) } }
    end

    # 返回单个加密配置；缺失的已知 key 会按空值返回。
    def show
      render json: { data: serialized_encrypted_config(@encrypted_config) }
    end

    # 新增或更新加密配置，只允许写入系统认识的 key 和字段。
    def create
      @encrypted_config =
        Motor::EncryptedConfig.find_or_initialize_by(key: @encrypted_config.key).tap do |config|
          config.value = @encrypted_config.value
        end

      if @encrypted_config.save
        render json: { data: serialized_encrypted_config(@encrypted_config) }
      else
        render_validation_errors(@encrypted_config)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    private

    # 构造按当前权限脱敏的配置序列化器。
    def encrypted_config_serializer
      @encrypted_config_serializer ||= Motor::EncryptedConfigSerializer.new(current_ability)
    end

    # 读取配置 key 并归一化为模型可写入的参数。
    def encrypted_config_params
      key = params.expect(data: [:key])[:key].to_s

      ensure_known_config_key!(key)

      { key: key, value: encrypted_config_value(key) }
    end

    # 处理缺失配置：无权限返回 403，未知 key 返回校验错误，已知 key 返回空值。
    def render_missing_encrypted_config
      unless current_ability.can?(:read, Motor::EncryptedConfig)
        render json: { errors: ['You are not authorized to access this page.'] }, status: :forbidden

        return
      end

      key = params.expect(:key)

      return render_unknown_config_key unless Motor::EncryptedConfig.known_key?(key)

      render json: { data: { key: key, value: nil } }
    end

    # 对单条加密配置执行权限感知序列化。
    def serialized_encrypted_config(config)
      encrypted_config_serializer.as_json(config)
    end

    # 按配置类型提取允许保存的 value 字段。
    def encrypted_config_value(key)
      case key
      when Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY
        permitted_value(data: [{ value: [DATABASE_CONFIG_FIELDS] }])
      when Motor::EncryptedConfig::EMAIL_SMTP_KEY
        permitted_value(data: [{ value: EMAIL_CONFIG_FIELDS }])
      when Motor::EncryptedConfig::FILES_STORAGE_KEY
        permitted_value(data: [{ value: [:service, { configs: STORAGE_CONFIG_FIELDS }] }])
      when Motor::EncryptedConfig::SLACK_CREDENTIALS_KEY
        permitted_value(data: [{ value: [:api_key] }])
      end
    end

    # 用 Rails 8 params.expect 读取嵌套 value 并转成普通 Ruby 值。
    def permitted_value(expectation)
      value = params.expect(expectation).fetch(:value)

      deep_parameter_value(value)
    end

    # 递归把 ActionController::Parameters 转成 Hash/Array，便于加密序列化。
    def deep_parameter_value(value)
      case value
      when ActionController::Parameters
        value.to_h
      when Array
        value.map { |item| deep_parameter_value(item) }
      else
        value
      end
    end

    # 拒绝未知配置 key，避免任意敏感数据写入加密表。
    def ensure_known_config_key!(key)
      raise UnknownConfigKey unless Motor::EncryptedConfig.known_key?(key)
    end

    # 返回未知 key 的标准校验错误。
    def render_unknown_config_key
      render json: { errors: { key: ['is not included in the list'] } }, status: :unprocessable_content
    end
  end
end
