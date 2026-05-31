# frozen_string_literal: true

require 'test_helper'

module Api
  class RolesTest < ActionDispatch::IntegrationTest
    setup do
      @actor = create_admin_user(roles: [Motor::Role.superadmin])
      sign_in @actor, scope: :admin_user
    end

    test 'rejects role with invalid rules' do
      post '/admin/api/roles',
           params: { role: { name: 'broken', rules: [{ subjects: ['all'], actions: [] }] } },
           as: :json

      assert_response :unprocessable_content
      assert_includes json_response.dig('errors', 'rules'), 'must include subjects and actions'
    end

    test 'prevents deleting superadmin role' do
      role = Motor::Role.superadmin

      delete "/admin/api/roles/#{role.id}", as: :json

      assert_response :unprocessable_content
      assert Motor::Role.exists?(role.id)
    end

    test 'prevents downgrading superadmin role' do
      role = Motor::Role.superadmin

      put "/admin/api/roles/#{role.id}",
          params: { role: { name: Motor::Role::SUPERADMIN, rules: [{ subjects: ['all'], actions: ['read'] }] } },
          as: :json

      assert_response :unprocessable_content
      assert Motor::Role.manage_all_rules?(role.reload.rules)
    end

    test 'allows partial superadmin update when full access remains' do
      role = Motor::Role.superadmin

      put "/admin/api/roles/#{role.id}",
          params: { role: { rules: [Motor::Role::DEFAULT_RULE] } },
          as: :json

      assert_response :success
      assert_equal Motor::Role::SUPERADMIN, role.reload.name
    end

    test 'prevents deleting assigned role' do
      role = create_role(name: 'manager', rules: [{ subjects: ['all'], actions: ['read'] }])
      create_admin_user(email: 'assigned@example.com', roles: [role])

      delete "/admin/api/roles/#{role.id}", as: :json

      assert_response :unprocessable_content
      assert Motor::Role.exists?(role.id)
    end
  end
end
