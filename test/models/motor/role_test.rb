# frozen_string_literal: true

require 'test_helper'

module Motor
  class RoleTest < ActiveSupport::TestCase
    test 'filters blank rules before validation' do
      role = Motor::Role.new(
        name: 'reader',
        rules: [
          { subjects: [], actions: [], attributes: [], conditions: [] },
          { subjects: ['all'], actions: ['read'], attributes: [], conditions: [{ key: '', value: [] }] }
        ]
      )

      assert_predicate role, :valid?
      assert_equal(
        [{ 'subjects' => ['all'], 'actions' => ['read'], 'attributes' => [], 'conditions' => [] }],
        role.rules
      )
    end

    test 'rejects rules without actions' do
      role = Motor::Role.new(name: 'broken', rules: [{ subjects: ['all'], actions: [] }])

      assert_not_predicate role, :valid?
      assert_includes role.errors[:rules], 'must include subjects and actions'
    end

    test 'detects manage all rules' do
      assert Motor::Role.manage_all_rules?([{ subjects: ['all'], actions: ['manage'] }])
      assert_not Motor::Role.manage_all_rules?([{ subjects: ['all'], actions: ['read'] }])
    end

    test 'default role helpers do not conflict with active record connection roles' do
      create_role(name: 'temporary')

      assert_nothing_raised { Motor::Role.delete_all }
    end
  end
end
