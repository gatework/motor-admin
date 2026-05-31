# frozen_string_literal: true

require 'test_helper'

class SetDbConnectionAndDefineArModelsTest < ActiveSupport::TestCase
  test 'includes named concerns into motor controllers' do
    assert_operator Motor::ApplicationController, :<, Motor::SetDbConnectionAndDefineArModels
    assert_operator Motor::DataController, :<, Motor::MaybeSetDbConnectionAndDefineArModels
  end

  test 'does not duplicate callbacks when prepare hooks run repeatedly' do
    3.times { Rails.application.reloader.prepare! }

    assert_equal 1, callback_count(Motor::ApplicationController, :set_db_connection_and_define_ar_models)
    assert_equal 1, callback_count(Motor::DataController, :maybe_set_db_connection_and_define_ar_models)
  end

  private

  # 统计控制器回调链中指定 filter 的数量。
  def callback_count(controller, filter)
    controller._process_action_callbacks.count { |callback| callback.filter == filter }
  end
end
