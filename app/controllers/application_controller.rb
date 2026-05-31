# frozen_string_literal: true

# 管理后台页面基类，统一处理初始化跳转、登录鉴权和公开访问身份。
class ApplicationController < ActionController::Base
  before_action :maybe_redirect_to_setup
  before_action :maybe_redirect_from_setup

  before_action :maybe_set_public_user
  before_action :authenticate_admin_user!, unless: :setup_path?

  before_action :set_devise_mailer_default_url_options

  private

  # 公开访问模式下为匿名访问设置 public 角色用户。
  def maybe_set_public_user
    @current_admin_user = Motor::AdminUser.public if current_admin_user.nil? && Motor.with_public_access?
  end

  # 根据当前管理员和请求上下文构造页面权限对象。
  def current_ability
    Motor::Ability.new(current_admin_user, request)
  end

  # 未初始化且访问非 setup 页面时跳转到初始化页。
  def maybe_redirect_to_setup
    return if setup_path?
    return unless new_setup?

    redirect_to admin_setup_path
  end

  # 初始化完成后避免继续停留在 setup 页面。
  def maybe_redirect_from_setup
    return unless setup_path?
    return if new_setup?

    redirect_to motor_admin_path
  end

  # 判断系统是否处于没有活跃管理员的初始化状态。
  def new_setup?
    current_admin_user.nil? && Motor::AdminUser.active.none?
  end

  # 判断当前请求是否为 setup 页面。
  def setup_path?
    request.path == admin_setup_path
  end

  # 按当前请求设置 Devise 邮件链接默认地址。
  def set_devise_mailer_default_url_options
    Devise::Mailer.default_url_options = {
      host: ENV['HOST'].presence || request.host,
      protocol: request.protocol,
      port: request.port
    }
  end
end
