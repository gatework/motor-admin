# frozen_string_literal: true

require 'test_helper'

module Motor
  class AuthorizationTokenTest < ActiveSupport::TestCase
    test 'encodes token with explicit algorithm and timestamps' do
      user = create_admin_user(email: 'token-payload@example.com')
      issued_at = Time.current

      token =
        with_stubbed_singleton_method(Motor::AuthorizationToken, :secret_key_base, -> { 'test-secret' }) do
          Motor::AuthorizationToken.encode(user, expires_in: 15.minutes, issued_at: issued_at)
        end

      payload, header = JWT.decode(
        token,
        'test-secret',
        true,
        { algorithm: Motor::AuthorizationToken::ALGORITHM }
      )

      assert_equal Motor::AuthorizationToken::ALGORITHM, header['alg']
      assert_equal user.id, payload['uid']
      assert_equal user.email, payload['email']
      assert_equal issued_at.to_i, payload['iat']
      assert_equal (issued_at + 15.minutes).to_i, payload['exp']
    end

    test 'rejects non-positive token ttl' do
      user = create_admin_user(email: 'token-ttl@example.com')

      error = assert_raises(ArgumentError) do
        Motor::AuthorizationToken.encode(user, expires_in: 0.seconds)
      end

      assert_equal 'expires_in must be positive', error.message
    end

    test 'decodes token payload' do
      user = create_admin_user(email: 'decode-token@example.com')

      with_stubbed_singleton_method(Motor::AuthorizationToken, :secret_key_base, -> { 'test-secret' }) do
        token = Motor::AuthorizationToken.encode(user)
        payload = Motor::AuthorizationToken.decode(token)

        assert_equal user.id, payload[:uid]
        assert_equal user.email, payload[:email]
      end
    end

    test 'authenticates active admin user from token' do
      user = create_admin_user(email: 'authenticate-token@example.com')

      with_stubbed_singleton_method(Motor::AuthorizationToken, :secret_key_base, -> { 'test-secret' }) do
        token = Motor::AuthorizationToken.encode(user)

        assert_equal user, Motor::AuthorizationToken.authenticate(token)
      end
    end

    test 'rejects expired token' do
      user = create_admin_user(email: 'expired-token@example.com')

      with_stubbed_singleton_method(Motor::AuthorizationToken, :secret_key_base, -> { 'test-secret' }) do
        token = Motor::AuthorizationToken.encode(user, expires_in: 1.minute, issued_at: 2.minutes.ago)

        assert_raises(Motor::AuthorizationToken::InvalidToken) do
          Motor::AuthorizationToken.decode(token)
        end
      end
    end

    test 'rejects token for soft deleted admin user' do
      user = create_admin_user(email: 'deleted-auth-token@example.com')

      with_stubbed_singleton_method(Motor::AuthorizationToken, :secret_key_base, -> { 'test-secret' }) do
        token = Motor::AuthorizationToken.encode(user)
        user.update!(deleted_at: Time.current)

        assert_raises(Motor::AuthorizationToken::InvalidToken) do
          Motor::AuthorizationToken.authenticate(token)
        end
      end
    end

    test 'rejects token for locked admin user' do
      user = create_admin_user(email: 'locked-auth-token@example.com')

      with_stubbed_singleton_method(Motor::AuthorizationToken, :secret_key_base, -> { 'test-secret' }) do
        token = Motor::AuthorizationToken.encode(user)
        user.update!(locked_at: Time.current)

        assert_raises(Motor::AuthorizationToken::InvalidToken) do
          Motor::AuthorizationToken.authenticate(token)
        end
      end
    end
  end
end
