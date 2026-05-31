# frozen_string_literal: true

require 'test_helper'

class ImpersonateTest < ActionDispatch::IntegrationTest
  test 'signs in user with valid impersonate token' do
    user = create_admin_user(email: 'target@example.com')
    token = user.impersonate_token

    assert_no_match(%r{[+/=]}, token)

    get "/impersonate/#{token}"

    assert_redirected_to '/admin'
  end

  test 'rejects invalid impersonate token' do
    create_admin_user

    get '/impersonate/not-a-valid-token'

    assert_response :forbidden
  end

  test 'rejects soft deleted user impersonate token' do
    user = create_admin_user(email: 'deleted-target@example.com')
    create_admin_user(email: 'active-admin@example.com')
    token = user.impersonate_token

    user.update!(deleted_at: Time.current)

    get "/impersonate/#{token}"

    assert_response :forbidden
  end

  test 'rejects locked user impersonate token' do
    user = create_admin_user(email: 'locked-target@example.com')
    token = user.impersonate_token

    user.update!(locked_at: Time.current)

    get "/impersonate/#{token}"

    assert_response :forbidden
  end
end
