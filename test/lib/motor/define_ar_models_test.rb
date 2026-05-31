# frozen_string_literal: true

require 'test_helper'

module Motor
  class DefineArModelsTest < ActiveSupport::TestCase
    test 'connection cache key includes schema search path' do
      public_model = fake_model_for_schema('public')
      tenant_model = fake_model_for_schema('tenant_a')

      assert_not_equal(
        Motor::DefineArModels.connection_url_hash(public_model),
        Motor::DefineArModels.connection_url_hash(tenant_model)
      )
    end

    test 'schema digest queries use stable ordering' do
      assert_includes(
        Motor::DefineArModels::PG_SELECT_SCHEMA_MD5,
        'ORDER BY t.table_schema, t.table_name, t.ordinal_position'
      )
      assert_includes(
        Motor::DefineArModels::PG_SELECT_TABLES_QUERY,
        'ORDER BY schemaname, tablename'
      )
      assert_includes(
        Motor::DefineArModels::MYSQL_SELECT_SCHEMA_MD5,
        'ORDER BY table_schema, table_name, ordinal_position'
      )
    end

    test 'defined models schema digest is independent from insertion order' do
      store = Motor::DefineArModels::DEFINED_CLASS_SCHEMA_MD5_STORE
      original_store = store.dup

      store.clear
      store['TenantB::Record'] = 'bbb'
      store['TenantA::Record'] = 'aaa'
      first_digest = Motor::DefineArModels.defined_models_schema_md5

      store.clear
      store['TenantA::Record'] = 'aaa'
      store['TenantB::Record'] = 'bbb'

      assert_equal first_digest, Motor::DefineArModels.defined_models_schema_md5
    ensure
      store.clear
      store.merge!(original_store)
    end

    private

    # 构造带 schema_search_path 的假模型连接对象。
    def fake_model_for_schema(schema_search_path)
      connection = Object.new
      connection_config = Struct.new(:url).new('postgres://localhost/app')

      connection.define_singleton_method(:schema_search_path) { schema_search_path }

      Object.new.tap do |model|
        model.define_singleton_method(:connection_db_config) { connection_config }
        model.define_singleton_method(:connection) { connection }
      end
    end
  end
end
