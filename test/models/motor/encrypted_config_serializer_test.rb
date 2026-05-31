# frozen_string_literal: true

require 'test_helper'

module Motor
  class EncryptedConfigSerializerTest < ActiveSupport::TestCase
    test 'exposes sensitive values for managers' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::SLACK_CREDENTIALS_KEY,
        value: { api_key: 'secret' }
      )

      serialized = Motor::EncryptedConfigSerializer.new(ability(can_manage: true)).as_json(config)

      assert_equal({ key: 'slack.credentials', value: { 'api_key' => 'secret' } }, serialized)
    end

    test 'masks nested sensitive values for read only users' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
        value: [{ name: 'primary', url: 'postgres://localhost/app', schema_search_path: 'public' }]
      )

      serialized = Motor::EncryptedConfigSerializer.new(ability(can_manage: false)).as_json(config)

      assert_equal(
        {
          key: 'database.credentials',
          value: [{ 'name' => 'primary', 'url' => '[FILTERED]', 'schema_search_path' => 'public' }]
        },
        serialized
      )
    end

    private

    # 构造只响应 can? 的最小权限对象。
    def ability(can_manage:)
      Class.new do
        define_method(:can?) do |action, subject|
          can_manage && action == :manage && subject == Motor::EncryptedConfig
        end
      end.new
    end
  end
end
