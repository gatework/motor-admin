# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/BlockLength, Naming/MethodName, Naming/VariableName
class UpgradeMotorApiActions < ActiveRecord::Migration[7.0]
  # 返回迁移内临时 API 配置模型，供旧动作生成表单时复用配置。
  def _MotorApiConfig
    @_MotorApiConfig ||= Class.new(ActiveRecord::Base) do
      self.table_name = 'motor_api_configs'

      encrypts :credentials

      serialize :credentials, coder: Motor::HashSerializer
      serialize :preferences, coder: Motor::HashSerializer

      attribute :preferences, default: -> { ActiveSupport::HashWithIndifferentAccess.new }
      attribute :credentials, default: -> { ActiveSupport::HashWithIndifferentAccess.new }
    end
  end

  # 返回迁移内临时表单模型，用于承载由旧 API 动作转换出的表单。
  def _MotorForm
    @_MotorForm ||= Class.new(ActiveRecord::Base) do
      self.table_name = 'motor_forms'

      serialize :preferences, coder: Motor::HashSerializer
    end
  end

  # 返回迁移内临时资源模型，用于遍历旧资源动作配置。
  def _MotorResource
    @_MotorResource ||= Class.new(ActiveRecord::Base) do
      self.table_name = 'motor_resources'

      serialize :preferences, coder: Motor::HashSerializer
    end
  end

  # 将资源里的旧 API 动作转换为表单动作，并生成对应表单和 API 配置。
  def up
    _MotorResource.find_each do |resource|
      resource.preferences.fetch(:actions, []).each do |action|
        next unless action[:action_type] == 'api'

        api_path = action[:preferences][:api_path]
        api_url = api_path[%r{\Ahttps?://[^/]+}]
        api_path = api_path.delete_prefix(api_url).sub(%r{\A/?}, '/') if api_url

        api_config =
          if api_url
            _MotorApiConfig.create_with(url: api_url).find_or_create_by!(name: api_url.sub(%r{\Ahttps?://}))
          else
            _MotorApiConfig.create_with(url: '/').find_or_create_by!(name: 'origin')
          end

        resource_display_name = (resource[:preferences][:display_name] || resource.name).titleize.singularize

        form = _MotorForm.create_with(
          api_config_name: api_config.name,
          api_path: api_path.sub(/\{{1,2}\w+\}{1,2}/, '{{id}}'),
          http_method: 'POST',
          preferences: {
            fields: [{
              name: 'id',
              display_name: resource_display_name,
              default_value: '',
              field_type: 'reference',
              reference: { model_name: resource.name },
              validators: [{ required: true }]
            }]
          }
        ).find_or_create_by!(
          name: "#{action[:display_name]} #{resource_display_name}"
        )

        action[:action_type] = 'form'
        action[:preferences] = { form_id: form.id }
      end

      resource.save!
    end
  end

  # 旧动作转换不可逆，保留空回滚以兼容迁移接口。
  def down; end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/BlockLength, Naming/MethodName, Naming/VariableName
