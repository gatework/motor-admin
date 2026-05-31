# frozen_string_literal: true

module Api
  # 管理后台角色 API，维护角色名称和权限规则。
  class RolesController < ApiBaseController
    load_and_authorize_resource class: 'Motor::Role'

    # 返回角色列表，按创建顺序稳定展示。
    def index
      render json: { data: @roles.order(:id) }
    end

    # 创建角色和权限规则。
    def create
      if @role.save
        render json: { data: @role }
      else
        render_validation_errors(@role)
      end
    end

    # 更新角色，超级管理员角色必须保留完整管理权限。
    def update
      if invalid_superadmin_update?
        @role.errors.add(:base, 'Superadmin role must keep full access.')

        render_validation_errors(@role)
      elsif @role.update(role_params)
        render json: { data: @role }
      else
        render_validation_errors(@role)
      end
    end

    # 删除角色，禁止删除超级管理员角色和仍被用户使用的角色。
    def destroy
      if @role.superadmin?
        @role.errors.add(:base, 'Superadmin role cannot be removed.')

        render_validation_errors(@role)
      elsif @role.admin_users.exists?
        @role.errors.add(:base, 'Role is assigned to users.')

        render_validation_errors(@role)
      else
        @role.destroy!

        head :ok
      end
    end

    private

    # 提取角色名称和嵌套权限规则参数。
    def role_params
      params.expect(role: [:name, { rules: [[{
                      subjects: [],
                      actions: [],
                      attributes: [],
                      conditions: [[:key, { value: [] }]]
                    }]] }])
    end

    # 判断本次更新是否破坏超级管理员角色约束。
    def invalid_superadmin_update?
      return false unless @role.superadmin?

      next_name = role_params.fetch(:name, @role.name)
      next_rules = role_params.key?(:rules) ? role_params[:rules] : @role.rules

      next_name != Motor::Role::SUPERADMIN || !Motor::Role.manage_all_rules?(next_rules)
    end
  end
end
