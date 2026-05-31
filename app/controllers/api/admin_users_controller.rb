# frozen_string_literal: true

module Api
  # 管理后台用户 API，负责用户列表、邀请、资料更新和软删除。
  class AdminUsersController < ApiBaseController
    before_action :build_admin_user, only: :create
    load_and_authorize_resource class: 'Motor::AdminUser'
    before_action :ensure_admin_user_active, only: %i[show update destroy]

    # 返回所有未软删除管理员，并预加载角色避免列表页 N+1。
    def index
      render json: serialized_user_data(
        @admin_users.active.preload(:roles).order(:id)
      )
    end

    # 返回单个管理员资料。
    def show
      render json: serialized_user_data(@admin_user)
    end

    # 创建管理员；同邮箱软删除记录会被恢复，活跃重复邮箱会被拒绝。
    def create
      return render_validation_errors(@admin_user) if @admin_user_already_active

      if @admin_user.save
        render json: serialized_user_data(@admin_user)
      else
        render_validation_errors(@admin_user)
      end
    end

    # 更新管理员资料，保护最后一个超级管理员的角色不被移除。
    def update
      if removing_last_superadmin_role?
        @admin_user.errors.add(:roles, 'must keep at least one superadmin')

        render_validation_errors(@admin_user)
      elsif @admin_user.update(update_admin_user_params)
        render json: serialized_user_data(@admin_user)
      else
        render_validation_errors(@admin_user)
      end
    end

    # 软删除管理员，禁止删除当前用户和系统最后一个超级管理员。
    def destroy
      if deleting_current_user?
        @admin_user.errors.add(:base, 'You cannot remove your own user.')

        render_validation_errors(@admin_user)
      elsif @admin_user.last_superadmin?
        @admin_user.errors.add(:base, 'You must keep at least one superadmin.')

        render_validation_errors(@admin_user)
      else
        @admin_user.update!(deleted_at: Time.current)

        head :ok
      end
    end

    # 向目标管理员发送 Devise 重置密码邮件。
    def reset_password
      @admin_user = Motor::AdminUser.active.find(params.expect(:admin_user_id))

      authorize!(:manage, @admin_user)

      set_devise_mailer_default_url_options

      @admin_user.send_reset_password_instructions

      head :ok
    end

    private

    # 构建创建/恢复用管理员对象，并标记活跃邮箱冲突。
    def build_admin_user
      @admin_user = Motor::AdminUser.find_by(email: admin_user_params[:email])
      @admin_user_already_active = @admin_user && @admin_user.deleted_at.blank?

      if @admin_user_already_active
        @admin_user.errors.add(:email, :taken)

        return
      end

      @admin_user ||= Motor::AdminUser.new(roles: [Motor::Role.admin])

      # 已软删除账号复用原记录恢复，避免唯一邮箱索引阻止重新邀请。
      @admin_user.restore_from_soft_delete(admin_user_params)
    end

    # 统一管理员 JSON 输出，避免泄漏模拟登录 token 等敏感字段。
    def serialized_user_data(user)
      {
        data: user.as_json(only: %i[id email first_name last_name locked_at],
                           include: %i[roles])
      }
    end

    # 读取管理员创建/更新参数。
    def admin_user_params
      params.expect(admin_user: [:email, :first_name, :last_name, :password, { role_ids: [] }])
    end

    # 更新时丢弃空密码，避免把空字符串写入 Devise 密码字段。
    def update_admin_user_params
      admin_user_params.tap do |attributes|
        attributes.delete(:password) if attributes[:password].blank?
      end
    end

    # 防止通过 show/update/destroy 访问已软删除管理员。
    def ensure_admin_user_active
      raise ActiveRecord::RecordNotFound if @admin_user.deleted_at.present?
    end

    # 按当前请求动态设置 Devise 邮件链接的 host/protocol/port。
    def set_devise_mailer_default_url_options
      Devise::Mailer.default_url_options = {
        host: ENV['HOST'].presence || request.host,
        protocol: request.protocol,
        port: request.port
      }
    end

    # 判断本次删除目标是否为当前登录用户。
    def deleting_current_user?
      current_admin_user&.id == @admin_user.id
    end

    # 判断更新是否会让最后一个超级管理员失去超级管理员角色。
    def removing_last_superadmin_role?
      return false unless @admin_user.last_superadmin?
      return false unless admin_user_params.key?(:role_ids)

      role_ids = admin_user_params[:role_ids].map(&:to_i)

      role_ids.exclude?(Motor::Role.superadmin.id)
    end
  end
end
