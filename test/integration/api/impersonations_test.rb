# frozen_string_literal: true

require 'test_helper'

module Api
  class ImpersonationsTest < ActionDispatch::IntegrationTest
    setup do
      @actor = create_admin_user(roles: [Motor::Role.superadmin])
      @target = create_admin_user(email: 'target@example.com')

      sign_in @actor, scope: :admin_user
    end

    test 'creates impersonate token for manageable user' do
      post '/admin/api/impersonations',
           params: { admin_user_id: @target.id },
           as: :json

      assert_response :success
      assert_equal @target.id, Motor::AdminUser.from_impersonate_token(json_response.dig('data', 'token')).id
    end

    test 'rejects user without manage permission' do
      sign_out @actor

      reader_role = create_role(
        name: 'admin-user-reader',
        rules: [{ subjects: ['Motor::AdminUser'], actions: ['read'] }]
      )
      reader = create_admin_user(email: 'reader@example.com', roles: [reader_role])

      sign_in reader, scope: :admin_user

      post '/admin/api/impersonations',
           params: { admin_user_id: @target.id },
           as: :json

      assert_response :forbidden
    end

    test 'rejects locked target user' do
      @target.update!(locked_at: Time.current)

      post '/admin/api/impersonations',
           params: { admin_user_id: @target.id },
           as: :json

      assert_response :unprocessable_content
      assert_equal ['Admin user cannot be impersonated'], json_response['errors']
    end
  end
end
