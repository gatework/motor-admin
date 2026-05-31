# frozen_string_literal: true

module Api
  module Rest
    # 对外 REST API 基类，统一处理 session 和 Bearer Token 两类管理员身份。
    class BaseController < ApiBaseController
      before_action :authenticate_rest_admin_user!

      # 返回当前 REST 请求识别出的管理员，保持 public 以便生产日志 payload 显式调用。
      def current_admin_user
        @current_admin_user || session_admin_user
      end

      private

      # 请求进入 REST 控制器前校验身份，失败时输出标准 401 Bearer 响应。
      def authenticate_rest_admin_user!
        @current_admin_user = session_admin_user || bearer_admin_user

        return if @current_admin_user

        response.set_header('WWW-Authenticate', 'Bearer')
        render json: { errors: ['Unauthorized'] }, status: :unauthorized
      end

      # 为 Motor 查询执行逻辑提供统一的当前用户入口。
      def current_user
        current_admin_user
      end

      # 从 Devise/Warden session 中取管理员，兼容后台页面已登录后直接调用 REST。
      def session_admin_user
        admin_user = request.env['warden']&.user(scope: :admin_user, run_callbacks: false)

        return unless active_admin_user?(admin_user)

        admin_user
      rescue ArgumentError
        nil
      end

      # 从 Authorization Bearer Token 中恢复管理员，失败时交给统一 401 响应处理。
      def bearer_admin_user
        token = bearer_token

        return if token.blank?

        Motor::AuthorizationToken.authenticate(token)
      rescue Motor::AuthorizationToken::InvalidToken
        nil
      end

      # 解析标准 Authorization: Bearer <token> 请求头。
      def bearer_token
        request.authorization.to_s.match(/\ABearer\s+(.+)\z/i)&.[](1)
      end

      # Lazily initialize dynamic data connections for authenticated REST requests that need them.
      def maybe_set_db_connection_and_define_ar_models
        return if Motor::DefineConnectionClasses.already_defined?

        Motor::DefineConnectionClasses.call
      end

      # 过滤软删除和锁定账号，避免 REST API 使用已失效身份。
      def active_admin_user?(admin_user)
        admin_user.present? &&
          admin_user.deleted_at.blank? &&
          (!admin_user.respond_to?(:access_locked?) || !admin_user.access_locked?)
      end
    end
  end
end
