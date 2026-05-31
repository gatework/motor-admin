# frozen_string_literal: true

module Api
  # 管理后台初始化 API，只允许在无管理员时创建首位超级管理员。
  class SetupsController < ApiBaseController
    class AlreadySetupError < StandardError; end

    skip_authorization_check

    rescue_from AlreadySetupError, with: :render_already_setup

    # 在系统尚未初始化时创建首位超级管理员并直接登录。
    def create
      raise AlreadySetupError if Motor::AdminUser.active.exists?

      user = build_superadmin_user

      if user.save
        sign_in(user)

        render json: { data: user.as_json }
      else
        render json: { errors: user.errors.as_json }, status: :unprocessable_content
      end
    end

    private

    # 读取初始化管理员所需字段。
    def admin_user_params
      params.expect(admin_user: %i[first_name last_name email password])
    end

    # 构建或恢复首位超级管理员，确保角色为 superadmin。
    def build_superadmin_user
      Motor::AdminUser.find_or_initialize_by(email: admin_user_params[:email]).tap do |user|
        user.assign_attributes(admin_user_params.merge(deleted_at: nil))
        user.roles = [Motor::Role.superadmin]
      end
    end

    # 已初始化时返回冲突响应。
    def render_already_setup
      render json: { errors: ['Motor Admin is already set up.'] }, status: :conflict
    end
  end
end
