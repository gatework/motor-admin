# frozen_string_literal: true

require 'test_helper'

class SetActiveStorageConfigsTest < ActiveSupport::TestCase
  test 'includes storage config concern into application controllers' do
    assert_operator ApplicationController, :<, SetActiveStorageConfigs
    assert_operator Motor::ApplicationController, :<, SetActiveStorageConfigs
  end

  test 'does not duplicate callbacks when prepare hooks run repeatedly' do
    3.times { Rails.application.reloader.prepare! }

    assert_equal 1, callback_count(ApplicationController, :set_active_storage_configs)
    assert_equal 1, callback_count(Motor::ApplicationController, :set_active_storage_configs)
  end

  test 'enables path style for s3 compatible endpoints' do
    options = ApplicationController.new.send(
      :storage_service_options,
      'aws_s3',
      { endpoint: 'http://minio.test', bucket: 'files' }.with_indifferent_access
    )

    assert_equal true, options[:force_path_style]
  end

  test 'parses google credentials json' do
    options = ApplicationController.new.send(
      :storage_service_options,
      'google',
      { credentials: '{"project_id":"demo"}' }.with_indifferent_access
    )

    assert_equal({ 'project_id' => 'demo' }, options[:credentials])
  end

  private

  # 统计控制器回调链中指定 filter 的数量。
  def callback_count(controller, filter)
    controller._process_action_callbacks.count { |callback| callback.filter == filter }
  end
end
