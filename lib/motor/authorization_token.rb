# frozen_string_literal: true

require 'jwt'

module Motor
  module AuthorizationToken
    DEFAULT_TTL = 2.hours

    module_function

    def encode(admin_user, expires_in: DEFAULT_TTL, issued_at: Time.current)
      raise ArgumentError, 'admin user is required' unless admin_user

      expires_at = issued_at + expires_in
      payload = {
        uid: admin_user.id,
        email: admin_user.email,
        exp: expires_at.to_i
      }

      JWT.encode(payload, secret_key_base)
    end

    def header(admin_user, expires_in: DEFAULT_TTL, issued_at: Time.current)
      "Bearer #{encode(admin_user, expires_in: expires_in, issued_at: issued_at)}"
    end

    def secret_key_base
      secret = Rails.application.secret_key_base.presence || ENV['SECRET_KEY_BASE'].presence

      raise 'SECRET_KEY_BASE is not configured' if secret.blank?

      secret
    end
  end
end
