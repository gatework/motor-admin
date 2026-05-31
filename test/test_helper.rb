# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'rails/test_help'
require 'devise/test/integration_helpers'

module MotorAdminTestHelpers
  # 创建测试角色，默认授予完整管理权限。
  def create_role(name: "role-#{SecureRandom.hex(4)}", rules: [Motor::Role::DEFAULT_RULE])
    Motor::Role.create!(name: name, rules: rules)
  end

  # 创建测试管理员并按需模拟软删除状态。
  def create_admin_user(email: "user-#{SecureRandom.hex(4)}@example.com", roles: [Motor::Role.admin], deleted_at: nil)
    Motor::AdminUser.create!(
      email: email,
      password: 'password',
      first_name: 'Test',
      last_name: 'User',
      roles: roles
    ).tap do |user|
      user.update_column(:deleted_at, deleted_at) if deleted_at
    end
  end

  # 临时替换单例方法，测试结束后恢复原实现。
  def with_stubbed_singleton_method(object, method_name, replacement)
    singleton_class = object.singleton_class
    original_method = object.method(method_name)

    singleton_class.define_method(method_name) do |*args, **kwargs, &block|
      replacement.call(*args, **kwargs, &block)
    end

    yield
  ensure
    singleton_class.define_method(method_name, original_method)
  end
end

module ActiveSupport
  class TestCase
    include MotorAdminTestHelpers

    setup do
      Motor::AdminUserRole.delete_all
      Motor::AdminUser.delete_all
      Motor::Role.delete_all
      Motor::EncryptedConfig.delete_all
      Motor::AdminUsers::ROLES_CACHE.clear
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      # 预热 Devise 映射，避免 Rails lazy routes 下测试登录先于 Warden session serializer 初始化。
      Devise.mappings
    end

    # 解析当前响应 JSON，简化集成测试断言。
    def json_response
      JSON.parse(response.body)
    end
  end
end
