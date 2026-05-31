# frozen_string_literal: true

require 'test_helper'

module Api
  class AdminUsersTest < ActionDispatch::IntegrationTest
    setup do
      @actor = create_admin_user(roles: [Motor::Role.superadmin])
      sign_in @actor, scope: :admin_user
    end

    test 'creates admin user' do
      post '/admin/api/admin_users',
           params: { admin_user: admin_user_payload(email: 'new@example.com') },
           as: :json

      assert_response :success
      assert_equal 'new@example.com', json_response.dig('data', 'email')
      assert_nil json_response.dig('data', 'impersonate_token')
    end

    test 'does not expose impersonate tokens in user list' do
      create_admin_user(email: 'listed@example.com')

      get '/admin/api/admin_users', as: :json

      assert_response :success
      assert(json_response.fetch('data').all? { |user| user.exclude?('impersonate_token') })
    end

    test 'restores soft deleted user with same email' do
      role = Motor::Role.admin
      deleted_user = create_admin_user(email: 'restore@example.com', roles: [role], deleted_at: 1.day.ago)

      post '/admin/api/admin_users',
           params: { admin_user: admin_user_payload(email: 'restore@example.com', role_ids: [role.id]) },
           as: :json

      assert_response :success
      assert_equal deleted_user.id, json_response.dig('data', 'id')
      assert_nil deleted_user.reload.deleted_at
    end

    test 'rejects duplicate active email' do
      create_admin_user(email: 'taken@example.com')

      post '/admin/api/admin_users',
           params: { admin_user: admin_user_payload(email: 'taken@example.com') },
           as: :json

      assert_response :unprocessable_content
      assert json_response.dig('errors', 'email').present?
    end

    test 'ignores blank password on update' do
      target = create_admin_user(email: 'blank-password-update@example.com')
      encrypted_password = target.encrypted_password

      put "/admin/api/admin_users/#{target.id}",
          params: {
            admin_user: {
              email: target.email,
              first_name: 'Updated',
              password: '',
              role_ids: target.role_ids
            }
          },
          as: :json

      assert_response :success
      assert_equal 'Updated', target.reload.first_name
      assert_equal encrypted_password, target.encrypted_password
    end

    test 'prevents deleting current user' do
      delete "/admin/api/admin_users/#{@actor.id}", as: :json

      assert_response :unprocessable_content
      assert_nil @actor.reload.deleted_at
    end

    test 'prevents deleting last superadmin' do
      sign_out @actor
      actor = create_admin_user(email: 'manager@example.com', roles: [Motor::Role.admin])
      sign_in actor, scope: :admin_user

      delete "/admin/api/admin_users/#{@actor.id}", as: :json

      assert_response :unprocessable_content
      assert_nil @actor.reload.deleted_at
    end

    test 'does not show soft deleted user' do
      deleted_user = create_admin_user(email: 'deleted-show@example.com', deleted_at: 1.day.ago)

      get "/admin/api/admin_users/#{deleted_user.id}", as: :json

      assert_response :not_found
    end

    test 'does not reset password for soft deleted user' do
      deleted_user = create_admin_user(email: 'deleted-reset@example.com', deleted_at: 1.day.ago)

      post "/admin/api/admin_users/#{deleted_user.id}/reset_password", as: :json

      assert_response :not_found
    end

    private

    # 构造管理员 API 请求体。
    def admin_user_payload(email:, role_ids: [Motor::Role.admin.id])
      {
        email: email,
        first_name: 'Admin',
        last_name: 'User',
        password: 'password',
        role_ids: role_ids
      }
    end
  end
end
