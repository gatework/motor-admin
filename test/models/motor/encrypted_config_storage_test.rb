# frozen_string_literal: true

require 'test_helper'

module Motor
  class EncryptedConfigStorageTest < ActiveSupport::TestCase
    test 'rejects incomplete storage config' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::FILES_STORAGE_KEY,
        value: { service: 'aws_s3' }
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], 'must include configs'
    end

    test 'accepts aws storage config with required fields' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::FILES_STORAGE_KEY,
        value: {
          service: 'aws_s3',
          configs: {
            access_key_id: 'access-key',
            secret_access_key: 'secret',
            region: 'us-east-1',
            bucket: 'attachments'
          }
        }
      )

      assert_predicate config, :valid?
    end

    test 'rejects unsupported storage service' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::FILES_STORAGE_KEY,
        value: { service: 'unknown', configs: {} }
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], 'must use supported storage service'
    end

    test 'rejects storage config missing service fields' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::FILES_STORAGE_KEY,
        value: { service: 'aws_s3', configs: { access_key_id: 'access-key' } }
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], 'storage configs must include secret_access_key, region, bucket'
    end

    test 'rejects invalid google credentials json' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::FILES_STORAGE_KEY,
        value: {
          service: 'google',
          configs: {
            credentials: '{not-json',
            project: 'project-id',
            bucket: 'attachments'
          }
        }
      )

      assert_not_predicate config, :valid?
      assert_includes config.errors[:value], 'google credentials must be valid JSON'
    end

    test 'accepts parsed google credentials hash' do
      config = Motor::EncryptedConfig.new(
        key: Motor::EncryptedConfig::FILES_STORAGE_KEY,
        value: {
          service: 'google',
          configs: {
            credentials: { 'type' => 'service_account' },
            project: 'project-id',
            bucket: 'attachments'
          }
        }
      )

      assert_predicate config, :valid?
    end
  end
end
