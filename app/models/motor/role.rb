# frozen_string_literal: true

module Motor
  # 管理后台角色，保存 CanCan 权限规则并提供系统默认角色。
  class Role < ::Motor::ApplicationRecord
    has_many :admin_user_roles, dependent: :destroy
    has_many :admin_users, through: :admin_user_roles

    attribute :rules, default: -> { [] }
    serialize :rules, coder: Motor::HashSerializer

    DEFAULT_RULE = {
      actions: %w[manage],
      subjects: %w[all],
      attributes: [],
      conditions: []
    }.freeze

    DEFAULT_ROLES = [
      SUPERADMIN = 'superadmin',
      ADMIN = 'admin',
      PUBLIC = 'public'
    ].freeze

    validates :name, presence: true, uniqueness: true

    before_validation :normalize_rules

    validate :rules_must_have_subjects_and_actions

    # 判断规则集合中是否包含对所有资源的 manage 权限。
    def self.manage_all_rules?(rules)
      Array.wrap(rules).any? do |rule|
        rule = rule.to_h.with_indifferent_access

        Array.wrap(rule[:subjects]).map(&:to_s).include?('all') &&
          Array.wrap(rule[:actions]).map(&:to_s).include?('manage')
      end
    end

    # 获取或创建系统超级管理员角色。
    def self.superadmin
      find_or_create_default_role(SUPERADMIN, rules: [DEFAULT_RULE])
    end

    # 获取或创建系统管理员角色。
    def self.admin
      find_or_create_default_role(ADMIN, rules: [DEFAULT_RULE])
    end

    # 获取或创建公开访问角色。
    def self.public
      find_or_create_default_role(PUBLIC, rules: [])
    end

    # 并发安全地获取或创建默认角色。
    def self.find_or_create_default_role(name, rules:)
      create_with(rules: rules).find_or_create_by(name: name)
    rescue ActiveRecord::RecordNotUnique
      retry
    end
    private_class_method :find_or_create_default_role

    # 判断当前角色是否为系统超级管理员角色。
    def superadmin?
      name == SUPERADMIN
    end

    private

    # 归一化所有权限规则并丢弃空规则。
    def normalize_rules
      self.rules = Array.wrap(rules).filter_map { |rule| normalize_rule(rule) }.reject { |rule| blank_rule?(rule) }
    end

    # 将单条规则转为稳定的字符串 key/value 结构。
    def normalize_rule(rule)
      return unless rule.respond_to?(:to_h)

      rule = rule.to_h.with_indifferent_access

      {
        'subjects' => normalize_values(rule[:subjects]),
        'actions' => normalize_values(rule[:actions]),
        'attributes' => normalize_values(rule[:attributes]),
        'conditions' => normalize_conditions(rule[:conditions])
      }
    end

    # 归一化规则中的字符串数组字段。
    def normalize_values(value)
      Array.wrap(value).filter_map { |item| item.presence&.to_s }
    end

    # 归一化条件数组，丢弃完全空白的条件。
    def normalize_conditions(conditions)
      Array.wrap(conditions).filter_map do |condition|
        next unless condition.respond_to?(:to_h)

        condition = condition.to_h.with_indifferent_access
        key = condition[:key].presence
        value = normalize_values(condition[:value])

        next if key.blank? && value.blank?

        { 'key' => key.to_s, 'value' => value }
      end
    end

    # 判断规则是否所有字段都为空。
    def blank_rule?(rule)
      rule.values.all?(&:blank?)
    end

    # 校验每条规则至少包含 subjects 和 actions。
    def rules_must_have_subjects_and_actions
      invalid_rules = rules.select { |rule| rule['subjects'].blank? || rule['actions'].blank? }

      errors.add(:rules, 'must include subjects and actions') if invalid_rules.any?
    end
  end
end
