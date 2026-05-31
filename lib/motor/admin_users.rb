# frozen_string_literal: true

module Motor
  # 管理员权限缓存，按用户和角色更新时间缓存角色名称与规则。
  module AdminUsers
    ROLES_CACHE = ActiveSupport::Cache::MemoryStore.new(size: 5.megabytes)

    module_function

    # 按用户和角色更新时间缓存角色属性，减少权限构建时的重复查询。
    def load_roles_from_cache(admin_user)
      ROLES_CACHE.fetch(roles_cache_key(admin_user)) do
        admin_user.roles.map(&:attributes)
      end
    end

    # 生成角色缓存键，未持久化用户按角色 id 集合回查更新时间。
    def roles_cache_key(admin_user)
      if admin_user.id
        [
          admin_user.id,
          cache_timestamp(admin_user.updated_at),
          cache_timestamp(admin_user.roles.maximum(:updated_at))
        ]
      else
        role_ids = admin_user.roles.filter_map(&:id)

        [nil, nil, cache_timestamp(Motor::Role.where(id: role_ids).maximum(:updated_at))]
      end.join(':')
    end

    # 将时间转成稳定字符串，空值用 nil 占位。
    def cache_timestamp(value)
      value&.utc&.strftime('%Y-%m-%dT%H:%M:%S.%6NZ') || 'nil'
    end
  end
end
