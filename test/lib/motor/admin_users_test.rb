# frozen_string_literal: true

require 'test_helper'

module Motor
  class AdminUsersTest < ActiveSupport::TestCase
    test 'roles cache key uses stable timestamp values' do
      role = create_role(name: 'cache-reader')
      user = create_admin_user(email: 'cache-key@example.com', roles: [role])

      assert_equal(
        [
          user.id,
          Motor::AdminUsers.cache_timestamp(user.updated_at),
          Motor::AdminUsers.cache_timestamp(role.updated_at)
        ].join(':'),
        Motor::AdminUsers.roles_cache_key(user)
      )
    end

    test 'roles cache key changes when a role changes' do
      role = create_role(name: 'cache-editor')
      user = create_admin_user(email: 'cache-change@example.com', roles: [role])

      cache_key = Motor::AdminUsers.roles_cache_key(user)
      role.update!(updated_at: 1.hour.from_now)

      assert_not_equal cache_key, Motor::AdminUsers.roles_cache_key(user)
    end
  end
end
