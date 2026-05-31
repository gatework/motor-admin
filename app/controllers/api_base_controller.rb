# frozen_string_literal: true

# 管理后台 API 基类，统一授权能力和 JSON 错误响应格式。
class ApiBaseController < ActionController::API
  rescue_from CanCan::AccessDenied, with: :render_access_denied
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

  # 根据当前管理员和请求上下文构造 CanCan 权限对象。
  def current_ability
    Motor::Ability.new(current_admin_user, request)
  end

  private

  # 将 CanCan 授权失败转换为 JSON 403 响应。
  def render_access_denied(error)
    Rails.logger.error(error)

    message =
      if params.expect(:action).in?(%w[create update destroy])
        I18n.t('motor.not_authorized_to_perform_action')
      else
        error.message
      end

    render json: { errors: [message] }, status: :forbidden
  end

  # 将找不到记录的异常转换为 404 空响应。
  def render_not_found
    head :not_found
  end

  # 将缺失必填参数的异常转换为 JSON 400 响应。
  def render_parameter_missing(error)
    render json: { errors: [error.message] }, status: :bad_request
  end

  # 输出 ActiveRecord 校验错误的统一 422 JSON 响应。
  def render_validation_errors(record)
    render json: { errors: record.errors.as_json }, status: :unprocessable_content
  end
end
