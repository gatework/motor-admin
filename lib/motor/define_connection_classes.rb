# frozen_string_literal: true

module Motor
  # 动态数据库连接类定义器，为每个已配置数据库生成独立 ActiveRecord 基类。
  module DefineConnectionClasses
    MUTEX = Mutex.new
    CONNECTION_SIGNATURES = ActiveSupport::HashWithIndifferentAccess.new

    module_function

    # 串行定义所有动态数据库连接类和对应模型。
    def call
      MUTEX.synchronize do
        define_connection_classes

        @already_defined = true
      end
    end

    # 根据加密配置定义连接类；未配置时回退演示数据库。
    def define_connection_classes
      database_configs = Motor::DatabaseConfigs.configured_entries

      return set_demo_db if database_configs.blank?

      base_classes =
        database_configs.map do |db_configs|
          db_name, db_url = db_configs.values_at('name', 'url')
          base_class = fetch_or_define_base_class(db_name)

          signature = Motor::DatabaseConfigs.connection_signature(db_configs)

          unless CONNECTION_SIGNATURES[base_class.name] == signature &&
                 Motor::DatabaseConfigs.connection_matches?(base_class, db_configs)
            base_class.establish_connection(url: db_url, prepared_statements: false)
            CONNECTION_SIGNATURES[base_class.name] = signature
          end

          # PostgreSQL 多 schema 场景需要在模型定义前设置搜索路径；其他适配器会安全跳过。
          Motor::DatabaseConfigs.apply_schema_search_path(base_class, db_configs['schema_search_path'])

          Motor::DefineArModels.call(base_class)
        end

      clear_removed_connection_classes(base_classes)
    end

    # 判断连接类是否已至少定义过一次。
    def already_defined?
      @already_defined
    end

    # 清理配置中已删除的连接类和其下动态模型。
    def clear_removed_connection_classes(base_classes)
      removed_base_class_names = Motor::DefineArModels::DEFINED_MODELS.keys - base_classes.map(&:name)

      removed_base_class_names.each do |removed_base_class_name|
        removed_base_class = removed_base_class_name.safe_constantize
        parent_module = removed_base_class_name.deconstantize.safe_constantize

        next unless removed_base_class

        Motor::DefineArModels.clear_models(removed_base_class)
        CONNECTION_SIGNATURES.delete(removed_base_class_name)

        next unless parent_module

        parent_module.send(:remove_const, removed_base_class_name.demodulize)
      end
    end

    # 建立演示数据库连接并定义默认 ResourceRecord 模型。
    def set_demo_db
      clear_removed_connection_classes([::ResourceRecord])

      ::ResourceRecord.establish_connection(Motor::DatabaseConfigs.demo_connection_config)
      CONNECTION_SIGNATURES.delete(::ResourceRecord.name)

      Motor::DefineArModels.call(::ResourceRecord)
    end

    # 获取或创建指定配置名称对应的动态 ActiveRecord 基类。
    def fetch_or_define_base_class(name)
      class_name = Motor::DatabaseConfigs.connection_class_name(name)

      "Motor::DatabaseClasses::#{class_name}".constantize
    rescue NameError
      if Motor::DatabaseConfigs.default_connection_name?(name)
        Motor::DatabaseClasses.const_set(:Default, ::ResourceRecord)
      else
        klass = Class.new(::ActiveRecord::Base)
        klass.abstract_class = true
        klass.inheritance_column = nil

        Motor::DatabaseClasses.const_set(class_name, klass)

        klass
      end
    end
  end
end
