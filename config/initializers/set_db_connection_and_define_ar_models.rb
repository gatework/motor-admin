# frozen_string_literal: true

module Motor
  # 管理后台页面请求前刷新动态连接和模型，确保配置变更后 schema 及时生效。
  module SetDbConnectionAndDefineArModels
    extend ActiveSupport::Concern

    included do
      prepend_before_action :set_db_connection_and_define_ar_models
    end

    # 每次页面请求前刷新连接和动态模型，确保配置变化立即生效。
    def set_db_connection_and_define_ar_models
      Motor::DefineConnectionClasses.call
    end
  end

  # 数据接口首次访问时懒加载动态模型，避免启动期重复扫描目标库。
  module MaybeSetDbConnectionAndDefineArModels
    extend ActiveSupport::Concern

    included do
      prepend_before_action :maybe_set_db_connection_and_define_ar_models
    end

    # 动态模型未初始化时按需初始化，已初始化则跳过昂贵扫描。
    def maybe_set_db_connection_and_define_ar_models
      return if Motor::DefineConnectionClasses.already_defined?

      Motor::DefineConnectionClasses.call
    end
  end
end

Rails.configuration.to_prepare do
  Motor::ApplicationController.include(Motor::SetDbConnectionAndDefineArModels)
  Motor::DataController.include(Motor::MaybeSetDbConnectionAndDefineArModels)
end
