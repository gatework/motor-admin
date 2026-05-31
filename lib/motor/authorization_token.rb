# frozen_string_literal: true

require 'jwt'

module Motor
  # 管理后台接口令牌生成器，负责签发可用于 API 调用的 Bearer Token。
  module AuthorizationToken
    # 令牌签发依赖的 Rails 密钥配置缺失。
    class ConfigurationError < StandardError; end
    class InvalidToken < StandardError; end

    DEFAULT_TTL = 2.hours
    ALGORITHM = 'HS256'

    module_function

    # 按管理员身份签发带过期时间和算法声明的 JWT。
    def encode(admin_user, expires_in: DEFAULT_TTL, issued_at: Time.current)
      raise ArgumentError, 'admin user is required' unless admin_user

      expires_in = normalized_expires_in(expires_in)
      expires_at = issued_at + expires_in
      payload = {
        uid: admin_user.id,
        email: admin_user.email,
        iat: issued_at.to_i,
        exp: expires_at.to_i
      }

      JWT.encode(payload, secret_key_base, ALGORITHM)
    end

    # 返回可直接用于 HTTP Authorization 请求头的 Bearer 值。
    def header(admin_user, expires_in: DEFAULT_TTL, issued_at: Time.current)
      "Bearer #{encode(admin_user, expires_in: expires_in, issued_at: issued_at)}"
    end

    # 校验并解码 JWT，失败统一抛出 InvalidToken。
    def decode(token)
      raise InvalidToken, 'Token is missing' if token.blank?

      payload, = JWT.decode(
        token,
        secret_key_base,
        true,
        { algorithm: ALGORITHM }
      )

      payload.with_indifferent_access
    rescue JWT::DecodeError => e
      raise InvalidToken, e.message
    end

    # 根据 token 恢复活跃管理员，并校验邮箱和锁定状态。
    def authenticate(token)
      payload = decode(token)
      admin_user = Motor::AdminUser.active.find_by(id: payload[:uid])

      raise InvalidToken, 'Admin user is not found' unless admin_user
      raise InvalidToken, 'Token admin user mismatch' unless admin_user.email.to_s == payload[:email].to_s
      raise InvalidToken, 'Admin user is locked' if admin_user.respond_to?(:access_locked?) && admin_user.access_locked?

      admin_user
    end

    # 兼容更语义化的调用名，返回 token 对应管理员。
    def admin_user_from_token(token)
      authenticate(token)
    end

    # 读取 JWT 签名密钥，缺失时明确抛出配置错误。
    def secret_key_base
      secret = Rails.application.secret_key_base.presence || ENV['SECRET_KEY_BASE'].presence

      raise ConfigurationError, 'SECRET_KEY_BASE is not configured' if secret.blank?

      secret
    end

    # 将 TTL 转成正整数秒数。
    def normalized_expires_in(expires_in)
      seconds = expires_in.to_i

      raise ArgumentError, 'expires_in must be positive' unless seconds.positive?

      seconds
    end
  end
end
