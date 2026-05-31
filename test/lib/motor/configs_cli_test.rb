# frozen_string_literal: true

require 'test_helper'

module Motor
  class ConfigsCliTest < ActiveSupport::TestCase
    test 'dump writes configs to file' do
      called = false

      with_stubbed_singleton_method(Motor::Configs::WriteToFile, :write_with_lock, -> { called = true }) do
        output, = capture_io { Motor::ConfigsCli.dump }

        assert called
        assert_includes output, 'motor.yml configs file has been updated'
      end
    end

    test 'load syncs configs from file with exceptions enabled' do
      call_options = nil

      with_stubbed_singleton_method(Motor::Configs::SyncFromFile, :call, ->(**options) { call_options = options }) do
        output, = capture_io { Motor::ConfigsCli.load }

        assert_equal({ with_exception: true }, call_options)
        assert_includes output, 'configs have been loaded from motor.yml'
      end
    end

    test 'reload clears configs inside reload flow' do
      cleared = false
      call_options = nil

      with_stubbed_singleton_method(Motor::Configs, :clear, -> { cleared = true }) do
        with_stubbed_singleton_method(Motor::Configs::SyncFromFile, :call, ->(**options) { call_options = options }) do
          output, = capture_io { Motor::ConfigsCli.reload }

          assert cleared
          assert_equal({ with_exception: true }, call_options)
          assert_includes output, 'configs have been re-loaded from motor.yml'
        end
      end
    end

    test 'sync requires remote url' do
      with_env('MOTOR_SYNC_REMOTE_URL' => nil, 'SYNC_REMOTE_URL' => nil,
               'MOTOR_SYNC_API_KEY' => 'secret', 'SYNC_API_KEY' => nil) do
        error = assert_raises(Motor::ConfigsCli::ConfigurationError) { Motor::ConfigsCli.sync }

        assert_equal(
          'Specify target app url using `MOTOR_SYNC_REMOTE_URL` or `SYNC_REMOTE_URL` env variable',
          error.message
        )
      end
    end

    test 'sync requires api key' do
      with_env('MOTOR_SYNC_REMOTE_URL' => 'https://example.test', 'SYNC_REMOTE_URL' => nil,
               'MOTOR_SYNC_API_KEY' => nil, 'SYNC_API_KEY' => nil) do
        error = assert_raises(Motor::ConfigsCli::ConfigurationError) { Motor::ConfigsCli.sync }

        assert_equal 'Specify sync api key using `MOTOR_SYNC_API_KEY` or `SYNC_API_KEY` env variable', error.message
      end
    end

    test 'sync fetches remote configs and writes local file' do
      sync_args = nil
      wrote_file = false

      with_env('MOTOR_SYNC_REMOTE_URL' => 'https://example.test', 'MOTOR_SYNC_API_KEY' => 'secret') do
        with_stubbed_singleton_method(Motor::Configs::SyncWithRemote, :call, ->(*args) { sync_args = args }) do
          with_stubbed_singleton_method(Motor::Configs::WriteToFile, :write_with_lock, -> { wrote_file = true }) do
            output, = capture_io { Motor::ConfigsCli.sync }

            assert_equal ['https://example.test', 'secret'], sync_args
            assert wrote_file
            assert_includes output, 'Motor Admin configurations have been synced with https://example.test'
          end
        end
      end
    end

    test 'sync accepts unprefixed environment variables from generated env file' do
      sync_args = nil

      with_env('MOTOR_SYNC_REMOTE_URL' => nil, 'MOTOR_SYNC_API_KEY' => nil,
               'SYNC_REMOTE_URL' => 'https://env-file.example.test', 'SYNC_API_KEY' => 'env-secret') do
        with_stubbed_singleton_method(Motor::Configs::SyncWithRemote, :call, ->(*args) { sync_args = args }) do
          with_stubbed_singleton_method(Motor::Configs::WriteToFile, :write_with_lock, -> {}) do
            capture_io { Motor::ConfigsCli.sync }
          end
        end
      end

      assert_equal ['https://env-file.example.test', 'env-secret'], sync_args
    end

    private

    # 临时设置环境变量并在测试结束后恢复。
    def with_env(values)
      previous_values = values.each_with_object({}) do |(key, value), acc|
        acc[key] = ENV.key?(key) ? ENV[key] : :__missing__

        value.nil? ? ENV.delete(key) : ENV[key] = value
      end

      yield
    ensure
      previous_values.each do |key, value|
        value == :__missing__ ? ENV.delete(key) : ENV[key] = value
      end
    end
  end
end
