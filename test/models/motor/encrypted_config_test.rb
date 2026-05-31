# frozen_string_literal: true

require 'test_helper'

module Motor
  class EncryptedConfigTest < ActiveSupport::TestCase
    test 'accepts known encrypted config keys' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::EMAIL_SMTP_KEY,
        value: {
          address: 'admin@example.com',
          host: 'smtp.example.com',
          port: 587,
          username: 'admin',
          password: 'secret'
        }
      )

      assert_predicate config, :valid?
    end

    test 'rejects unknown encrypted config keys' do
      config = Motor::EncryptedConfig.new(key: 'unknown.secret', value: { token: 'hidden' })

      assert_not_predicate config, :valid?
      assert_includes config.errors[:key], 'is not included in the list'
    end

    test 'allows empty database credentials list' do
      config = Motor::EncryptedConfig.new(key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY, value: [])

      assert_predicate config, :valid?
    end

    test 'rejects database credentials without name or url' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
        value: [{ name: 'primary' }, { name: ' ', url: 'postgres://localhost/app' }]
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], 'database configs must include name and url'
    end

    test 'rejects database credentials with unsupported url scheme' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
        value: [{ name: 'primary', url: 'ftp://localhost/app' }]
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], Motor::DatabaseConfigs::UNSUPPORTED_DATABASE_URL_MESSAGE
    end

    test 'rejects database credentials with incomplete database url' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
        value: [{ name: 'primary', url: 'postgres:localhost/app' }]
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], Motor::DatabaseConfigs::UNSUPPORTED_DATABASE_URL_MESSAGE
    end

    test 'rejects database credentials with malformed url encoding' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
        value: [{ name: 'primary', url: 'postgres://localhost/app?sslmode=%' }]
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], Motor::DatabaseConfigs::UNSUPPORTED_DATABASE_URL_MESSAGE
    end

    test 'rejects duplicate database config names' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
        value: [
          { name: 'Reporting DB', url: 'postgres://localhost/reporting' },
          { name: 'reporting-db', url: 'postgres://localhost/reporting_replica' }
        ]
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], Motor::DatabaseConfigs::DUPLICATE_DATABASE_NAME_MESSAGE
    end

    test 'rejects unsafe database schema search paths' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY,
        value: [
          {
            name: 'primary',
            url: 'postgres://localhost/app',
            schema_search_path: 'public;DROP SCHEMA public'
          }
        ]
      )

      assert_not_predicate config, :valid?
      assert_includes(
        config.errors[:value],
        Motor::DatabaseConfigs::INVALID_SCHEMA_SEARCH_PATH_MESSAGE
      )
    end

    test 'rejects incomplete email smtp config' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::EMAIL_SMTP_KEY,
        value: { host: 'smtp.example.com' }
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], 'must include address, port, username, password'
    end
  end
end
