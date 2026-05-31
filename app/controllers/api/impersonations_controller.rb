# frozen_string_literal: true

module Api
  # 受授权保护的模拟登录 token 生成 API，避免在用户列表中泄漏可用 token。
  class ImpersonationsController < ApiBaseController
    rescue_from Motor::AdminUser::ImpersonationUnavailable, with: :render_impersonation_unavailable

    # 生成目标管理员的一次性模拟登录 token，调用方必须拥有 manage 权限。
    def create
      admin_user = Motor::AdminUser.active.find(params.expect(:admin_user_id))

      authorize!(:manage, admin_user)

      render json: { data: { token: admin_user.impersonate_token } }
    end

    private

    # 将不可模拟登录的业务错误转换为 422 JSON 响应。
    def render_impersonation_unavailable(error)
      render json: { errors: [error.message] }, status: :unprocessable_content
    end
  end
end
