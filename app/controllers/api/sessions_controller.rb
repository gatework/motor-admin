# frozen_string_literal: true

module Api
  # 管理后台会话 API，负责退出当前管理员登录状态。
  class SessionsController < ApiBaseController
    skip_authorization_check

    # 注销当前管理员 session。
    def destroy
      sign_out current_admin_user

      head :ok
    end
  end
end
