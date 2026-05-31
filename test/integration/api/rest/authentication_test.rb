# frozen_string_literal: true

require 'test_helper'

module Api
  module Rest
    class AuthenticationTest < ActionDispatch::IntegrationTest
      setup do
        @admin_user = create_admin_user(roles: [Motor::Role.superadmin])
      end

      test 'requires authentication' do
        get '/admin/api/rest/reports', as: :json

        assert_response :unauthorized
        assert_equal ['Unauthorized'], json_response['errors']
        assert_equal 'Bearer', response.headers['WWW-Authenticate']
      end

      test 'does not initialize REST data models before authentication' do
        initialized_dynamic_connections = false

        with_stubbed_singleton_method(Motor::DefineConnectionClasses, :call, lambda {
          initialized_dynamic_connections = true
        }) do
          get '/admin/api/rest/data/motor__roles', as: :json
        end

        assert_response :unauthorized
        assert_not initialized_dynamic_connections
      end

      test 'rejects invalid bearer token' do
        get '/admin/api/rest/reports',
            headers: { 'Authorization' => 'Bearer invalid-token' },
            as: :json

        assert_response :unauthorized
        assert_equal ['Unauthorized'], json_response['errors']
      end

      test 'accepts bearer token' do
        with_stubbed_singleton_method(Motor::AuthorizationToken, :secret_key_base, -> { 'test-secret' }) do
          get '/admin/api/rest/reports',
              headers: { 'Authorization' => Motor::AuthorizationToken.header(@admin_user) },
              as: :json
        end

        assert_response :ok
        assert_equal %w[queries dashboards alerts], json_response['data'].keys
      end

      test 'accepts existing admin session' do
        sign_in @admin_user, scope: :admin_user

        get '/admin/api/rest/reports', as: :json

        assert_response :ok
      end

      test 'keeps current_admin_user public for production log payloads' do
        assert Api::Rest::BaseController.public_method_defined?(:current_admin_user)
      end
    end
  end
end
