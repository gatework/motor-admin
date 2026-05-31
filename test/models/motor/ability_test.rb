# frozen_string_literal: true

require 'test_helper'

module Motor
  class AbilityTest < ActiveSupport::TestCase
    test 'grants manage all from superadmin role' do
      user = create_admin_user(roles: [Motor::Role.superadmin])
      ability = Motor::Ability.new(user)

      assert ability.can?(:manage, :all)
    end

    test 'normalizes current user id condition' do
      user = create_admin_user
      ability = Motor::Ability.new(user)

      conditions = ability.normalize_conditions_argument(
        [{ 'key' => 'author.id', 'value' => ['current_user_id'] }],
        user
      )

      assert_equal({ author: { id: [user.id] } }, conditions)
    end

    test 'normalizes current user email condition' do
      user = create_admin_user(email: 'owner@example.com')
      ability = Motor::Ability.new(user)

      conditions = ability.normalize_conditions_argument(
        [{ 'key' => 'email', 'value' => ['current_user_email'] }],
        user
      )

      assert_equal({ email: ['owner@example.com'] }, conditions)
    end

    test 'ignores empty condition values' do
      user = create_admin_user
      ability = Motor::Ability.new(user)

      assert_empty ability.normalize_conditions_argument([{ 'key' => 'id', 'value' => [] }], user)
    end

    test 'merges multiple conditions under the same association' do
      user = create_admin_user(email: 'owner@example.com')
      ability = Motor::Ability.new(user)

      conditions = ability.normalize_conditions_argument(
        [
          { 'key' => 'author.id', 'value' => ['current_user_id'] },
          { 'key' => 'author.email', 'value' => ['current_user_email'] }
        ],
        user
      )

      assert_equal({ author: { id: [user.id], email: ['owner@example.com'] } }, conditions)
    end
  end
end
