# frozen_string_literal: true

module Motor
  # 管理员与角色的关联关系，变更时触发用户时间戳更新以刷新权限缓存。
  class AdminUserRole < ::Motor::ApplicationRecord
    belongs_to :admin_user, touch: true
    belongs_to :role
  end
end
