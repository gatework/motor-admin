# frozen_string_literal: true

# 管理后台模拟登录入口，校验一次性签名链接后切换为目标用户。
class ImpersonateController < ApplicationController
  skip_before_action :authenticate_admin_user!

  # 校验模拟登录 token，成功后切换 session 并跳转后台首页。
  def show
    user = Motor::AdminUser.from_impersonate_token(params.expect(:token))

    return head :forbidden unless user

    sign_in(user)

    redirect_to motor_admin_path
  end
end
