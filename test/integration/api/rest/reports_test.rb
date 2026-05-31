# frozen_string_literal: true

require 'test_helper'

module Api
  module Rest
    class ReportsTest < ActionDispatch::IntegrationTest
      setup do
        Motor::Alert.delete_all
        Motor::Dashboard.delete_all
        Motor::Query.delete_all

        @admin_user = create_admin_user(roles: [Motor::Role.superadmin])
        sign_in @admin_user, scope: :admin_user
      end

      test 'lists report groups' do
        query = create_query(name: 'REST Query')
        Motor::Dashboard.create!(title: 'REST Dashboard', preferences: { layout: [{ query_id: query.id }] })
        Motor::Alert.create!(
          query: query,
          name: 'REST Alert',
          to_emails: 'admin@example.com',
          preferences: { interval: 'every day', timezone: 'UTC' }
        )

        get '/admin/api/rest/reports', as: :json

        assert_response :ok
        assert_equal ['REST Query'], json_response.dig('data', 'queries').pluck('name')
        assert_equal ['REST Dashboard'], json_response.dig('data', 'dashboards').pluck('title')
        assert_equal ['REST Alert'], json_response.dig('data', 'alerts').pluck('name')
      end

      test 'shows saved report query' do
        query = create_query(name: 'REST Show Query')

        get "/admin/api/rest/reports/queries/#{query.id}", as: :json

        assert_response :ok
        assert_equal 'REST Show Query', json_response.dig('data', 'name')
      end

      test 'runs saved report query with variables and current user variables' do
        query = create_query(name: 'REST Run Query')
        captured_variables = nil
        result = Motor::Queries::RunQuery::QueryResult.new(
          data: [[1]],
          columns: [{ name: 'value', display_name: 'Value', column_type: 'integer', is_array: false }]
        )

        with_stubbed_singleton_method(Motor::Queries::RunQuery, :call, lambda { |_query, variables_hash:, **_options|
          captured_variables = variables_hash
          result
        }) do
          post "/admin/api/rest/reports/queries/#{query.id}/run",
               params: { variables: { region: 'apac', current_user_email: 'spoof@example.com' } },
               as: :json
        end

        assert_response :ok
        assert_equal [[1]], json_response['data']
        assert_equal 'apac', captured_variables['region']
        assert_equal @admin_user.id, captured_variables['current_user_id']
        assert_equal @admin_user.email, captured_variables['current_user_email']
      end

      test 'initializes dynamic connections before running saved report query' do
        query = create_query(name: 'REST Run Query With Fresh Connections')
        callback_events = []
        result = Motor::Queries::RunQuery::QueryResult.new(
          data: [[1]],
          columns: [{ name: 'value', display_name: 'Value', column_type: 'integer', is_array: false }]
        )

        with_stubbed_singleton_method(Motor::DefineConnectionClasses, :already_defined?, -> { false }) do
          with_stubbed_singleton_method(Motor::DefineConnectionClasses, :call, -> { callback_events << :define }) do
            with_stubbed_singleton_method(Motor::Queries::RunQuery, :call, lambda { |_query, **_options|
              callback_events << :run_query
              result
            }) do
              post "/admin/api/rest/reports/queries/#{query.id}/run", as: :json
            end
          end
        end

        assert_response :ok
        assert_equal %i[define run_query], callback_events
      end

      test 'returns report query errors' do
        query = create_query(name: 'REST Error Query')
        result = Motor::Queries::RunQuery::QueryResult.new(error: 'Invalid SQL')

        with_stubbed_singleton_method(Motor::Queries::RunQuery, :call, ->(_query, **_options) { result }) do
          post "/admin/api/rest/reports/queries/#{query.id}/run", as: :json
        end

        assert_response :unprocessable_entity
        assert_equal 'Invalid SQL', json_response.dig('errors', 0, 'detail')
      end

      private

      # 创建保存查询，供 reports REST API 测试复用。
      def create_query(name:)
        Motor::Query.create!(
          name: name,
          sql_body: 'select 1 as value',
          preferences: {}
        )
      end
    end
  end
end
