# frozen_string_literal: true

module Motor
  # 管理后台权限对象，把角色规则转换为 CanCan 可执行能力。
  class Ability
    include CanCan::Ability

    CURRENT_USER_ID_KEY = 'current_user_id'
    CURRENT_USER_EMAIL_KEY = 'current_user_email'

    # 初始化当前管理员的权限，内置通知/提醒权限后再应用角色规则。
    def initialize(admin_user, _request = nil)
      return if admin_user.nil?

      can :read, Motor::Tag
      can :read, Motor::NoteTag
      can :manage, Motor::Notification, recipient: admin_user
      can :manage, Motor::Reminder, author: admin_user

      admin_user.rules.each { |rule| apply_rule(rule, admin_user) }
    end

    # 将单条角色规则转换为 CanCan 的 can 调用参数。
    def apply_rule(rule, admin_user)
      subjects, actions, attributes, conditions =
        rule.values_at('subjects', 'actions', 'attributes', 'conditions')

      return if subjects.blank? || actions.blank?

      arguments = [actions.map(&:to_sym), normalize_subjects_argument(subjects)]
      arguments << attributes.map(&:to_sym) if attributes.present?
      arguments << normalize_conditions_argument(conditions, admin_user)

      can(*arguments)
    end

    # 解析规则中的 subjects，all 映射到 CanCan 的全局资源。
    def normalize_subjects_argument(subjects)
      subjects = Array.wrap(subjects)

      return [:all] if subjects == ['all']

      subjects.filter_map(&:safe_constantize)
    end

    # 把前端保存的条件数组归一化为 CanCan 可识别的 Hash。
    def normalize_conditions_argument(conditions, admin_user)
      return {} if conditions.blank?

      conditions.each_with_object({}) do |condition, acc|
        apply_condition(acc, condition, admin_user)
      end
    end

    # 应用单个条件，支持点分隔字段和当前用户占位符。
    def apply_condition(acc, condition, admin_user)
      key, value = condition.values_at('key', 'value')

      return if blank_condition?(key, value)

      # 将 "author.id" 这类点分隔条件展开成 CanCan 可识别的嵌套 Hash。
      assign_nested_condition(acc, key.split('.'), normalize_condition_value(value, admin_user))
    end

    # 判断条件是否缺少可执行的字段或值。
    def blank_condition?(key, value)
      key.blank? || (value.is_a?(Array) && value.blank?)
    end

    # 将点分隔路径写入嵌套 Hash 的最终字段。
    def assign_nested_condition(acc, parts, value)
      final_key = parts.pop.to_sym
      target = nested_condition_target(acc, parts)

      target[final_key] = value
    end

    # 获取或创建嵌套条件中间层 Hash。
    def nested_condition_target(acc, parts)
      target = acc

      parts.each do |part|
        part_key = part.to_sym

        target[part_key] = {} unless target[part_key].is_a?(Hash)
        target = target[part_key]
      end

      target
    end

    # 将 current_user_* 占位符替换为当前管理员真实字段值。
    def normalize_condition_value(value, admin_user)
      Array.wrap(value).map do |val|
        case val
        when CURRENT_USER_ID_KEY
          # 角色规则允许用当前用户占位符表达“只能访问自己的数据”。
          admin_user.id
        when CURRENT_USER_EMAIL_KEY
          admin_user.email
        else
          val
        end
      end
    end
  end
end
