# frozen_string_literal: true

module Motor
  # 设置主数据连接，优先连接用户配置的默认数据库，否则回退到演示 SQLite。
  module SetDbConnection
    module_function

    # 建立 ResourceRecord 主连接并记录已初始化状态。
    def call
      database_config = Motor::DatabaseConfigs.configured_entries.first

      if database_config
        connect_configured_database(database_config)
      else
        connect_demo_database
      end

      @already_set = true
    end

    # 判断主数据连接是否已经初始化过。
    def already_set?
      @already_set
    end

    # 按已保存配置连接业务数据库，并应用 schema_search_path。
    def connect_configured_database(database_config)
      signature = Motor::DatabaseConfigs.connection_signature(database_config)

      unless @connection_signature == signature &&
             Motor::DatabaseConfigs.connection_matches?(::ResourceRecord, database_config)
        ::ResourceRecord.establish_connection(url: database_config['url'], prepared_statements: false)
        @connection_signature = signature
      end

      Motor::DatabaseConfigs.apply_schema_search_path(::ResourceRecord, database_config['schema_search_path'])
    end

    # 回退连接本地演示 SQLite 数据库。
    def connect_demo_database
      ::ResourceRecord.establish_connection(Motor::DatabaseConfigs.demo_connection_config)

      @connection_signature = nil
    end
  end
end
