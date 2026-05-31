# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'

module Motor
  class DatabaseConfigsCopyTest < ActiveSupport::TestCase
    test 'copies demo database through a temporary file' do
      with_demo_database_paths do |root_path, target_path|
        with_stubbed_singleton_method(Rails, :root, -> { root_path }) do
          Motor::DatabaseConfigs.copy_demo_database(target_path)
        end

        assert_equal 'demo-data', target_path.binread
        assert_empty(root_path.children.select { |path| path.basename.to_s.end_with?('.tmp') })
      end
    end

    test 'does not overwrite existing demo database copy' do
      with_demo_database_paths do |root_path, target_path|
        target_path.binwrite('existing-data')

        with_stubbed_singleton_method(Rails, :root, -> { root_path }) do
          Motor::DatabaseConfigs.copy_demo_database(target_path)
        end

        assert_equal 'existing-data', target_path.binread
      end
    end

    private

    # 将 demo 数据库复制测试隔离到临时目录。
    def with_demo_database_paths
      Dir.mktmpdir do |dir|
        root_path = Pathname(dir)
        target_path = root_path.join('target.sqlite3')

        root_path.join(Motor::DatabaseConfigs::DEMO_DATABASE_FILENAME).binwrite('demo-data')

        yield root_path, target_path
      end
    end
  end
end
