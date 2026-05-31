# frozen_string_literal: true

require 'test_helper'

module Motor
  class AdminUserTest < ActiveSupport::TestCase
    test 'detects superadmin role' do
      user = create_admin_user(roles: [Motor::Role.superadmin])

      assert_predicate user, :superadmin?
    end

    test 'detects last active superadmin' do
      user = create_admin_user(roles: [Motor::Role.superadmin])

      assert_predicate user, :last_superadmin?

      create_admin_user(email: 'other@example.com', roles: [Motor::Role.superadmin])

      assert_not_predicate user.reload, :last_superadmin?
    end

    test 'active scope excludes soft deleted users' do
      active_user = create_admin_user(email: 'active@example.com')
      deleted_user = create_admin_user(email: 'deleted@example.com', deleted_at: 1.day.ago)

      assert_includes Motor::AdminUser.active, active_user
      assert_not_includes Motor::AdminUser.active, deleted_user
    end

    test 'soft deleted user is inactive for devise authentication' do
      user = create_admin_user(email: 'inactive@example.com', deleted_at: 1.day.ago)

      assert_not user.active_for_authentication?
      assert_equal :deleted_account, user.inactive_message
    end

    test 'does not load soft deleted user from impersonate token' do
      user = create_admin_user(email: 'impersonate-deleted@example.com')
      token = user.impersonate_token

      user.update!(deleted_at: Time.current)

      assert_nil Motor::AdminUser.from_impersonate_token(token)
    end

    test 'does not load locked user from impersonate token' do
      user = create_admin_user(email: 'impersonate-locked@example.com')
      token = user.impersonate_token

      user.update!(locked_at: Time.current)

      assert_nil Motor::AdminUser.from_impersonate_token(token)
    end

    test 'generates url safe impersonate token' do
      user = create_admin_user(email: 'impersonate-url-safe@example.com')
      token = user.impersonate_token

      assert_no_match(%r{[+/=]}, token)
      assert_equal user, Motor::AdminUser.from_impersonate_token(token)
    end

    test 'loads legacy raw verifier impersonate token' do
      user = create_admin_user(email: 'impersonate-legacy@example.com')
      token = Motor::AdminUser.impersonate_verifier.generate({ user_id: user.id }, expires_in: 1.hour)

      assert_equal user, Motor::AdminUser.from_impersonate_token(token)
    end

    test 'does not generate impersonate token for locked user' do
      user = create_admin_user(email: 'locked-token@example.com')

      user.update!(locked_at: Time.current)

      assert_raises(Motor::AdminUser::ImpersonationUnavailable) { user.impersonate_token }
    end

    test 'restores soft deleted user attributes' do
      role = Motor::Role.admin
      user = create_admin_user(email: 'restore@example.com', roles: [role], deleted_at: 1.day.ago)

      user.restore_from_soft_delete(
        email: 'restore@example.com',
        first_name: 'Restored',
        last_name: 'User',
        password: 'password',
        role_ids: [role.id]
      )

      assert_nil user.deleted_at
      assert_equal 'Restored', user.first_name
      assert_equal [role.id], user.role_ids
    end

    test 'memoizes empty role names and rules' do
      user = create_admin_user(email: 'empty-roles@example.com', roles: [])
      calls = 0
      load_roles = lambda do |_admin_user|
        calls += 1
        []
      end

      with_stubbed_singleton_method(Motor::AdminUsers, :load_roles_from_cache, load_roles) do
        assert_empty user.role_names
        assert_empty user.role_names
        assert_empty user.rules
        assert_empty user.rules
      end

      assert_equal 1, calls
    end
  end
end
