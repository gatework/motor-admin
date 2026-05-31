# frozen_string_literal: true

module Motor
  # 动态 ActiveRecord 模型定义器，根据目标数据库表结构生成模型、校验和关联。
  module DefineArModels
    EXCLUDE_TABLES = Set.new(
      %w[
        active_storage_blobs
        active_storage_variant_records
        motor_admin_user_roles
        motor_admin_users
        motor_alert_locks
        motor_alerts
        motor_dashboards
        motor_encrypted_configs
        motor_forms
        motor_resources
        motor_roles
        motor_taggable_tags
        motor_tags
        motor_api_configs
        motor_note_tag_tags
        motor_note_tags
        motor_notes
        motor_notifications
        motor_reminders
        active_storage_attachments
        ar_internal_metadata
        motor_audits
        motor_configs
        motor_queries
        schema_migrations
      ]
    ).freeze

    DEFINED_MODELS = ActiveSupport::HashWithIndifferentAccess.new
    TABLE_INDEXES_CACHE = ActiveSupport::HashWithIndifferentAccess.new
    ENUM_TYPE_VALUES_CACHE = ActiveSupport::HashWithIndifferentAccess.new

    TIMESTAMP_COLUMNS = [
      *ResourceRecord.timestamp_attributes_for_create,
      *ResourceRecord.timestamp_attributes_for_update
    ].freeze

    DEFINED_CLASS_SCHEMA_MD5_STORE = ActiveSupport::HashWithIndifferentAccess.new

    RUBY_CONSTANTS = Set.new(Object.constants.map(&:to_s)).freeze

    PG_SELECT_TABLES_QUERY = <<~SQL.squish
      select schemaname, tablename from pg_tables
      where schemaname NOT IN ('pg_catalog', 'information_schema')
      ORDER BY schemaname, tablename
    SQL

    PG_SELECT_SCHEMA_MD5 = <<~SQL.squish
      SELECT md5(string_agg(t::text, '' ORDER BY t.table_schema, t.table_name, t.ordinal_position)::text)
      FROM information_schema.columns as t WHERE table_schema IN (:schema)
    SQL

    MYSQL_SELECT_SCHEMA_MD5 = <<~SQL.squish
      SELECT * FROM information_schema.columns WHERE table_schema IN (:schema)
      ORDER BY table_schema, table_name, ordinal_position
    SQL

    module_function

    # 根据连接当前 schema 生成或刷新动态模型，并配置校验和关联。
    def call(base_class)
      schema_md5 = fetch_schemas_md5(base_class.connection)

      tables = load_tables(base_class.connection)

      clear_models(base_class) if schema_md5 != DEFINED_CLASS_SCHEMA_MD5_STORE[base_class.name]

      DEFINED_MODELS[base_class.name] ||= {}

      define_models(tables, base_class).each do |model|
        next unless model.table_exists?

        configure_defined_model(model, base_class)
      end

      DEFINED_CLASS_SCHEMA_MD5_STORE[base_class.name] = schema_md5

      base_class
    end

    # 返回所有已定义动态模型 schema 指纹的汇总 MD5，用于缓存失效。
    def defined_models_schema_md5
      schema_signatures =
        DEFINED_CLASS_SCHEMA_MD5_STORE.map { |class_name, schema_md5| "#{class_name}:#{schema_md5}" }.sort.join('|')

      Digest::MD5.hexdigest(schema_signatures)
    end

    # 清理指定基类下已定义的动态模型常量和 schema cache。
    def clear_models(base_class)
      models = DEFINED_MODELS[base_class.name]

      return if models.blank?

      base_class.connection.schema_cache.clear!

      base_constant = base_class.name.include?('::') ? base_class.name.demodulize.safe_constantize : Object

      models.each_value { |klass| base_constant.send(:remove_const, klass.name.demodulize) }

      DEFINED_MODELS.delete(base_class.name)
    end

    # 为表名集合逐个定义动态模型。
    def define_models(tables, base_class)
      tables.filter_map { |table_name| define_model(table_name, base_class) }
    end

    # 为单个业务表定义 ActiveRecord 动态模型。
    def define_model(table_name, base_class)
      return if EXCLUDE_TABLES.include?(table_name)

      class_name = defined_model_class_name(table_name, base_class)
      existing_class = class_name.safe_constantize

      return if existing_class && ActiveRecord::Base.descendants.include?(existing_class)

      model = Class.new(base_class)
      model.table_name = table_name
      model.ignored_columns += ignored_model_columns(model, base_class)

      DEFINED_MODELS[base_class.name][table_name] = model

      set_model_constant(base_class, class_name, model)
    end

    # 计算动态模型常量名，多数据库连接时嵌套在对应基类命名空间下。
    def defined_model_class_name(table_name, base_class)
      table_class_name = table_class_name(table_name)

      if base_class == ::ResourceRecord
        resource_record_class_name(table_class_name)
      else
        [base_class.name.demodulize, table_class_name].join('::')
      end
    end

    # 将表名转换为 Ruby 类名。
    def table_class_name(table_name)
      table_name.underscore.tr(' ', '_').classify
    end

    # 避免动态模型类名与 Ruby 内置常量冲突。
    def resource_record_class_name(table_class_name)
      "#{'Db' if RUBY_CONSTANTS.include?(table_class_name)}#{table_class_name}"
    end

    # 找出会覆盖基类实例方法的字段并加入 ignored_columns。
    def ignored_model_columns(model, base_class)
      # 表字段如果与 ActiveRecord/基类实例方法同名会覆盖方法调用，这里只忽略冲突字段。
      model.column_names.map(&:to_sym).intersection(base_class.instance_methods) - [:id]
    end

    # 为已定义模型配置主键、校验、关联和多对多透传关联。
    def configure_defined_model(model, base_class)
      assign_primary_key(model)
      define_model_validators(model)
      define_model_reflections(model, base_class)
      define_model_many_to_many(model) if join_table_model?(model)

      model
    end

    # 设置模型常量；冲突时追加 Record 后缀，命名空间缺失时动态创建模块。
    def set_model_constant(base_class, class_name, model)
      if class_name.safe_constantize
        Object.const_set("#{class_name}Record", model)
      else
        Object.const_set(class_name, model)
      end
    rescue NameError
      base_module   = base_class.name.demodulize.safe_constantize
      base_module ||= Object.const_set(base_class.name.demodulize, Module.new)

      base_module.const_set(class_name.demodulize, model)
    end

    # 没有显式主键时尝试用 id 或唯一非空索引字段作为主键。
    def assign_primary_key(model)
      return if model.primary_key

      indexes = fetch_table_indexes(model)

      primary_key_column =
        model.columns.find do |column|
          next true if column.name == 'id'
          next if column.null

          indexes.find { |index| index.unique && index.columns == [column.name] }
        end

      return unless primary_key_column

      model.primary_key = primary_key_column.name
    end

    # 为动态模型补充自动推断的校验器。
    def define_model_validators(model)
      define_presence_validators(model)
      define_enum_validators(model)
    end

    # 为 PostgreSQL enum 字段添加 inclusion 校验。
    def define_enum_validators(model)
      return if model.connection.class.to_s != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'

      model.columns.each do |column|
        next if column.type != :enum

        cache_key = connection_url_hash(model) + column.sql_type

        ENUM_TYPE_VALUES_CACHE[cache_key] ||=
          model.pluck(Arel.sql("unnest(enum_range(NULL::#{column.sql_type}))::text")).uniq

        model.validates_inclusion_of column.name.to_sym, in: ENUM_TYPE_VALUES_CACHE[cache_key]
      end
    end

    # 为非空、无默认值、非时间戳字段添加 presence 校验。
    def define_presence_validators(model)
      required_columns =
        model.columns.reject do |column|
          column.name == model.primary_key ||
            column.null ||
            column.default ||
            column.default_function ||
            column.type == :boolean ||
            column.name.in?(TIMESTAMP_COLUMNS)
        end

      return if required_columns.blank?

      model.validates_presence_of(required_columns.map(&:name))
    end

    # 为典型两端 belongs_to 的 join table 生成双向便捷关联。
    def define_model_many_to_many(model)
      ref_one, ref_two = model.reflections.values

      define_join_association(source_reflection: ref_one, target_reflection: ref_two)
      define_join_association(source_reflection: ref_two, target_reflection: ref_one)
    end

    # 在 join table 的一侧模型上定义穿透到另一侧模型的关联。
    def define_join_association(source_reflection:, target_reflection:)
      association_name =
        join_association_name(source_reflection: source_reflection, target_reflection: target_reflection)
      inverse_name =
        join_inverse_name(source_reflection: source_reflection, target_reflection: target_reflection)

      # join model 两侧 inverse 可能是 has_one 或 has_many，透传关联类型要跟随 inverse 类型。
      source_reflection.klass.public_send(join_association_type(source_reflection),
                                          association_name,
                                          through: source_reflection.inverse_of.name,
                                          inverse_of: inverse_name)
    end

    # 根据 inverse 类型选择 has_one 或 has_many。
    def join_association_type(reflection)
      reflection.inverse_of.has_one? ? :has_one : :has_many
    end

    # 计算 join table 穿透关联的名称。
    def join_association_name(source_reflection:, target_reflection:)
      if source_reflection.inverse_of.has_one?
        target_reflection.name
      else
        target_reflection.klass.table_name.split('.').first
      end.to_sym
    end

    # 计算 join table 穿透关联的 inverse_of 名称。
    def join_inverse_name(source_reflection:, target_reflection:)
      if target_reflection.inverse_of.has_one?
        source_reflection.name
      else
        source_reflection.klass.table_name.split('.').first
      end.to_sym
    end

    # 判断模型是否符合自动生成多对多关联的 join table 形态。
    def join_table_model?(model)
      join_columns = model.columns.reject do |column|
        column.name == 'id' || column.name.in?(TIMESTAMP_COLUMNS)
      end

      return false unless join_columns.size.in?([2, 3])
      return false if model.reflections.size != 2

      belongs_to_reflections = model.reflections.values.select(&:belongs_to?)

      return false if belongs_to_reflections.size != 2

      true
    end

    # 缓存并返回表索引信息，减少动态推断关联和主键时的 schema 查询。
    def fetch_table_indexes(model)
      cache_key = connection_url_hash(model) + model.table_name

      TABLE_INDEXES_CACHE[cache_key] ||= model.connection.indexes(model.table_name)
    end

    # 加载连接可见表；PostgreSQL 会按当前 schema_search_path 过滤。
    def load_tables(connection)
      return connection.tables unless defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)

      if connection.instance_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        search_schemas = connection.schema_search_path.split(/\s*,\s*/)

        connection.exec_query(PG_SELECT_TABLES_QUERY).rows.filter_map do |schema, table|
          table if search_schemas.blank? || search_schemas.include?(schema)
        end
      else
        connection.tables
      end
    end

    # 根据适配器计算 schema 指纹，用于判断是否需要重建动态模型。
    def fetch_schemas_md5(connection)
      if connection.class.name.include?('PostgreSQL')
        fetch_pg_schema_md5(connection)
      elsif connection.class.name.include?('Mysql2')
        fetch_mysql_schema_md5(connection)
      else
        Digest::MD5.hexdigest('')
      end
    end

    # 使用 information_schema 计算 PostgreSQL 当前 schema 的字段指纹。
    def fetch_pg_schema_md5(connection)
      schemas = connection.schema_search_path.split(/\s*,\s*/).presence || ['public']

      sql = ActiveRecord::Base.sanitize_sql_array([PG_SELECT_SCHEMA_MD5, { schema: schemas }])

      connection.exec_query(sql).rows.first.first
    end

    # 使用 information_schema 查询结果计算 MySQL 当前库的字段指纹。
    def fetch_mysql_schema_md5(connection)
      schema = connection.connection_class.connection_db_config.configuration_hash[:database]

      sql = ActiveRecord::Base.sanitize_sql_array([MYSQL_SELECT_SCHEMA_MD5, { schema: schema }])

      Digest::MD5.hexdigest(connection.exec_query(sql).rows.to_json)
    end

    # 根据 *_id 字段和已定义模型推断 belongs_to/has_one/has_many 关联。
    def define_model_reflections(model, base_class)
      model.columns.each do |column|
        next unless column.name.ends_with?('_id')
        next if column.try(:array?)

        belongs_to_name = column.name.delete_suffix('_id')

        next if model.columns_hash["#{belongs_to_name}_type"]

        ref_model = DEFINED_MODELS.dig(base_class.name, belongs_to_name.pluralize)

        next unless ref_model

        define_model_reflection(model, ref_model, column, belongs_to_name.to_sym)
      end
    end

    # 为一个外键字段定义 belongs_to，并在目标模型上定义对应 inverse 关联。
    def define_model_reflection(model, ref_model, column, belongs_to_name)
      is_has_one = fetch_table_indexes(model).any? { |index| index.unique && index.columns == [column.name] }
      inverse_of_name = (is_has_one ? model.name.demodulize.underscore : model.table_name.split('.').last).to_sym

      model.belongs_to(belongs_to_name, optional: column.null, inverse_of: inverse_of_name)

      if is_has_one
        ref_model.has_one(inverse_of_name, dependent: :destroy, inverse_of: belongs_to_name)
      else
        ref_model.has_many(inverse_of_name, dependent: :destroy, inverse_of: belongs_to_name)
      end
    end

    # 生成连接级缓存键，区分 URL、schema_search_path 和适配器。
    def connection_url_hash(model)
      Digest::SHA256.hexdigest(
        [
          model.connection_db_config.try(:url),
          model.connection.try(:schema_search_path),
          model.connection.class.name
        ].join("\0")
      )
    end
  end
end
