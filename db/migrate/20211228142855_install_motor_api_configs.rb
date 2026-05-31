# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Naming/MethodName, Naming/VariableName
class InstallMotorApiConfigs < ActiveRecord::Migration[7.0]
  # 返回迁移内临时 API 配置模型，避免依赖运行时业务模型版本。
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

  # 返回迁移内临时表单模型，用于迁移旧表单 API 地址配置。
  def _MotorForm
    @_MotorForm ||= Class.new(ActiveRecord::Base) do
      self.table_name = 'motor_forms'

      serialize :preferences, coder: Motor::HashSerializer
    end
  end

  # 返回迁移内临时查询模型，用于迁移旧查询 API 地址配置。
  def _MotorQuery
    @_MotorQuery ||= Class.new(ActiveRecord::Base) do
      self.table_name = 'motor_queries'

      serialize :preferences, coder: Motor::HashSerializer
    end
  end

  # 创建 API 配置表，并把旧表单和查询中的完整 API URL 拆分到配置表。
  def up
    create_table :motor_api_configs, if_not_exists: true do |t|
      t.column :name, :string, null: false
      t.column :url, :string, null: false
      t.column :preferences, :text, null: false
      t.column :credentials, :text, null: false
      t.column :description, :text
      t.column :deleted_at, :datetime

      t.timestamps

      t.index 'name',
              name: 'motor_api_configs_name_unique_index',
              unique: true,
              where: 'deleted_at IS NULL'
    end

    add_column :motor_forms, :api_config_name, :string

    _MotorForm.reset_column_information

    _MotorForm.find_each do |form|
      if form.api_path.starts_with?('http')
        url = form.api_path[%r{\Ahttps?://[^/]+}]

        if form.preferences[:default_values_api_path].present?
          form.preferences[:default_values_api_path] =
            form.preferences[:default_values_api_path].delete_prefix(url).sub(%r{\A/?}, '/')
        end

        form.update!(api_config_name: _MotorApiConfig.find_or_create_by!(name: url, url: url).name,
                     api_path: form.api_path.delete_prefix(url).sub(%r{\A/?}, '/'))
      else
        form.update!(api_config_name: _MotorApiConfig.find_or_create_by!(name: 'origin', url: '/').name)
      end
    end

    _MotorQuery.find_each do |query|
      next if query.preferences['api_path'].blank?

      if query.preferences['api_path'].starts_with?('http')
        url = query.preferences['api_path'][%r{\Ahttps?://[^/]+}]

        query.preferences['api_path'].delete(url)

        query.preferences['api_config_name'] = _MotorApiConfig.find_or_create_by!(name: url, url: url).name
      else
        query.preferences['api_config_name'] = _MotorApiConfig.find_or_create_by!(name: 'origin', url: '/').name
      end

      query.save!
    end

    change_column_null :motor_forms, :api_config_name, false

    _MotorApiConfig.find_or_create_by!(name: 'origin', url: '/')
  end

  # 移除 API 配置表和表单上的配置名称字段。
  def down
    remove_column :motor_forms, :api_config_name
    drop_table :motor_api_configs
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Naming/MethodName, Naming/VariableName
