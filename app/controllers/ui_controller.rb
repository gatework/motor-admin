# frozen_string_literal: true

# 管理后台前端入口，输出 Vue 应用启动所需的用户、路由和资源 schema 数据。
class UiController < ApplicationController
  helper_method :app_data_attributes

  before_action :set_i18n_locale

  # 渲染后台前端入口页。
  def index
    render :show
  end

  # 直接渲染后台前端入口页。
  def show; end

  private

  # 使用后台配置的语言设置当前 I18n locale。
  def set_i18n_locale
    I18n.locale = Motor::Config.find_by(key: 'language')&.value.presence || I18n.default_locale
  end

  # 生成前端启动需要的数据属性，包括当前用户、base_path 和权限裁剪后的 schema。
  def app_data_attributes
    {
      version: Motor::VERSION,
      base_path: Rails.application.routes.url_helpers.motor_admin_path,
      current_user: current_admin_user.as_json(only: %i[id email first_name last_name]),
      # schema 依赖当前权限实时裁剪，避免前端拿到不可访问资源的操作入口。
      schema: Motor::BuildSchema.call(Motor::Configs::LoadFromCache.load_cache_keys, current_ability)
    }
  end
end
