# frozen_string_literal: true

# 独立服务启动时自动迁移后台库，命令行任务不会重复触发。
ActiveRecord::Tasks::DatabaseTasks.migrate if Motor.server?
