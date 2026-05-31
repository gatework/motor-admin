# frozen_string_literal: true

require 'test_helper'

module Api
  module Rest
    class DataTest < ActionDispatch::IntegrationTest
      setup do
        @admin_user = create_admin_user(roles: [Motor::Role.superadmin])
        sign_in @admin_user, scope: :admin_user
      end

      test 'lists dynamic resource records' do
        Motor::Role.create!(name: 'rest-data-listed')

        get '/admin/api/rest/data/motor__roles',
            params: { fields: { motor_role: 'id,name' }, meta: 'count' },
            as: :json

        assert_response :ok
        assert_includes json_response.fetch('data').pluck('name'), 'rest-data-listed'
        assert_equal Motor::Role.count, json_response.dig('meta', 'count')
      end

      test 'initializes dynamic models before loading REST data resources' do
        callbacks = Api::Rest::DataController._process_action_callbacks
        before_action_filters = callbacks.select { |callback| callback.kind == :before }.map(&:filter)

        assert_includes before_action_filters, :maybe_set_db_connection_and_define_ar_models
        assert_includes before_action_filters, :load_and_authorize_resource

        assert_operator before_action_filters.index(:authenticate_rest_admin_user!),
                        :<,
                        before_action_filters.index(:maybe_set_db_connection_and_define_ar_models)
        assert_operator before_action_filters.index(:maybe_set_db_connection_and_define_ar_models),
                        :<,
                        before_action_filters.index(:load_and_authorize_resource)
      end

      test 'creates updates and destroys dynamic resource records' do
        post '/admin/api/rest/data/motor__roles',
             params: { data: { name: 'rest-data-created' } },
             as: :json

        assert_response :created
        role_id = json_response.dig('data', 'id')
        assert_equal 'rest-data-created', Motor::Role.find(role_id).name

        patch "/admin/api/rest/data/motor__roles/#{role_id}",
              params: { data: { name: 'rest-data-updated' } },
              as: :json

        assert_response :ok
        assert_equal 'rest-data-updated', Motor::Role.find(role_id).name

        delete "/admin/api/rest/data/motor__roles/#{role_id}", as: :json

        assert_response :ok
        assert_raises(ActiveRecord::RecordNotFound) { Motor::Role.find(role_id) }
      end
    end
  end
end
