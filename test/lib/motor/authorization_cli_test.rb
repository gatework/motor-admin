# frozen_string_literal: true

require 'test_helper'

module Motor
  class AuthorizationCliTest < ActiveSupport::TestCase
    test 'finds active admin user by email' do
      user = create_admin_user(email: 'active-token@example.com')

      assert_equal user, Motor::AuthorizationCli.find_admin_user(email: 'active-token@example.com')
    end

    test 'does not find soft deleted admin user' do
      user = create_admin_user(email: 'deleted-token@example.com')
      user.update!(deleted_at: Time.current)

      assert_raises(ActiveRecord::RecordNotFound) do
        Motor::AuthorizationCli.find_admin_user(email: 'deleted-token@example.com')
      end
    end

    test 'rejects locked admin user' do
      user = create_admin_user(email: 'locked-token@example.com')
      user.update!(locked_at: Time.current)

      error = assert_raises(ArgumentError) { Motor::AuthorizationCli.find_admin_user(id: user.id) }

      assert_equal 'Admin user is locked', error.message
    end

    test 'rejects zero ttl' do
      error = assert_raises(ArgumentError) { Motor::AuthorizationCli.parse_duration('0m') }

      assert_equal 'Invalid ttl: "0m"', error.message
    end
  end
end
