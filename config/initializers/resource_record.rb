# frozen_string_literal: true

# 目标业务数据库的抽象基类，动态模型都继承它以隔离后台自身数据库连接。
class ResourceRecord < ActiveRecord::Base
  self.abstract_class = true
  self.inheritance_column = nil

  CREATE_TIMESTAMP_COLUMNS = %w[inserted_at createdAt insertedAt].freeze
  UPDATE_TIMESTAMP_COLUMNS = %w[edited_at updatedAt editedAt].freeze

  # 为动态模型补充非 Rails 默认命名的创建时间字段。
  def self.timestamp_attributes_for_create
    super + CREATE_TIMESTAMP_COLUMNS
  end

  # 为动态模型补充非 Rails 默认命名的更新时间字段。
  def self.timestamp_attributes_for_update
    super + UPDATE_TIMESTAMP_COLUMNS
  end
end
