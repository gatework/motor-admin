# frozen_string_literal: true

require 'test_helper'

module Api
  class SetupsTest < ActionDispatch::IntegrationTest
    test 'creates first superadmin user' do
      post '/admin/api/setup',
           params: {
             admin_user: {
               email: 'owner@example.com',
               first_name: 'Owner',
               last_name: 'User',
               password: 'password'
             }
           },
           as: :json

      assert_response :success

      user = Motor::AdminUser.find_by!(email: 'owner@example.com')

      assert_predicate user, :superadmin?
    end

    test 'rejects setup when admin user already exists' do
      create_admin_user(email: 'existing@example.com')

      post '/admin/api/setup',
           params: {
             admin_user: {
               email: 'owner@example.com',
               first_name: 'Owner',
               last_name: 'User',
               password: 'password'
             }
           },
           as: :json

      assert_response :conflict
      assert_equal ['Motor Admin is already set up.'], json_response['errors']
    end

    test 'allows setup when only soft deleted users exist' do
      deleted_user = create_admin_user(email: 'owner@example.com', deleted_at: 1.day.ago)

      post '/admin/api/setup',
           params: {
             admin_user: {
               email: 'owner@example.com',
               first_name: 'Restored',
               last_name: 'Owner',
               password: 'password'
             }
           },
           as: :json

      assert_response :success
      assert_equal deleted_user.id, json_response.dig('data', 'id')

      deleted_user.reload

      assert_nil deleted_user.deleted_at
      assert_predicate deleted_user, :superadmin?
    end

    test 'redirects to setup when only soft deleted users exist' do
      create_admin_user(email: 'deleted@example.com', deleted_at: 1.day.ago)

      get '/admin/settings'

      assert_redirected_to '/admin/setup'
    end
  end
end
