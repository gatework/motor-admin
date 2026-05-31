# frozen_string_literal: true

require 'base64'

module Motor
  # 管理后台用户，封装登录身份、角色关系和权限规则缓存。
  class AdminUser < ::Motor::ApplicationRecord
    class ImpersonationUnavailable < StandardError; end

    IMPERSONATE_TOKEN_PURPOSE = :motor_admin_impersonate
    IMPERSONATE_TOKEN_TTL = 1.hour

    devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable

    has_many :admin_user_roles, dependent: :destroy
    has_many :roles, through: :admin_user_roles

    scope :active, -> { where(deleted_at: nil) }
    scope :superadmins, -> { joins(:roles).where(motor_roles: { name: Motor::Role::SUPERADMIN }).distinct }

    # 返回所有活跃超级管理员。
    def self.active_superadmins
      active.superadmins
    end

    # 构造公开访问模式下使用的匿名管理员对象。
    def self.public
      Motor::AdminUser.new(roles: [Motor::Role.public])
    end

    # 从模拟登录 token 中恢复目标管理员，并确认账号仍可登录。
    def self.from_impersonate_token(token)
      payload = impersonate_verifier.verified(decode_impersonate_token(token))
      payload = payload.with_indifferent_access if payload.respond_to?(:with_indifferent_access)
      user = active.find_by(id: payload[:user_id]) if payload.present?

      user if user&.impersonatable?
    end

    # 解码 URL 安全的 token，兼容旧的未编码 MessageVerifier token。
    def self.decode_impersonate_token(token)
      token = token.to_s
      decoded_token = Base64.urlsafe_decode64(token)

      decoded_token.include?(ActiveSupport::MessageVerifier::SEPARATOR) ? decoded_token : token
    rescue ArgumentError
      token
    end

    # 返回模拟登录 token 使用的 Rails MessageVerifier。
    def self.impersonate_verifier
      Rails.application.message_verifier(IMPERSONATE_TOKEN_PURPOSE)
    end

    # 默认记住管理员登录状态。
    def remember_me
      true
    end

    # Devise 登录态校验，软删除账号视为不可登录。
    def active_for_authentication?
      super && deleted_at.blank?
    end

    # 为软删除账号返回专用的 Devise 不活跃原因。
    def inactive_message
      deleted_at.present? ? :deleted_account : super
    end

    # 生成短期模拟登录 token，不可登录账号会被拒绝。
    def impersonate_token
      raise ImpersonationUnavailable, 'Admin user cannot be impersonated' unless impersonatable?

      # 使用 Rails MessageVerifier 统一签名和过期时间，避免手写摘要校验遗漏密钥边界。
      self.class.encode_impersonate_token(
        self.class.impersonate_verifier.generate({ user_id: id }, expires_in: IMPERSONATE_TOKEN_TTL)
      )
    end

    # 将 MessageVerifier token 编码成 URL 安全字符串。
    def self.encode_impersonate_token(token)
      Base64.urlsafe_encode64(token, padding: false)
    end

    # 判断账号是否持久化且当前可登录。
    def impersonatable?
      persisted? && active_for_authentication?
    end

    # 返回缓存后的角色名称列表。
    def role_names
      load_roles_from_cache unless defined?(@role_names)

      @role_names
    end

    # 返回缓存后的角色权限规则。
    def rules
      load_roles_from_cache unless defined?(@rules)

      @rules
    end

    # 判断管理员是否拥有超级管理员角色。
    def superadmin?
      role_names.include?(Motor::Role::SUPERADMIN)
    end

    # 判断当前账号是否是系统最后一个活跃超级管理员。
    def last_superadmin?
      return false unless persisted? && deleted_at.blank? && superadmin?

      self.class.active_superadmins.where.not(id: id).none?
    end

    # 用给定属性恢复软删除账号。
    def restore_from_soft_delete(attributes)
      assign_attributes(attributes.merge(deleted_at: nil))
    end

    private

    # 从全局缓存读取角色数据，并拆成 role_names 和 rules 实例缓存。
    def load_roles_from_cache
      roles = Motor::AdminUsers.load_roles_from_cache(self)

      @role_names = roles.pluck('name')
      @rules = roles.flat_map { |r| r['rules'] }
    end
  end
end
