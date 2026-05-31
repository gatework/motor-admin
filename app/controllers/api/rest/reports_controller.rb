# frozen_string_literal: true

module Api
  module Rest
    # 对外 reports REST API，暴露查询、仪表盘、告警和查询执行结果。
    class ReportsController < BaseController
      before_action :maybe_set_db_connection_and_define_ar_models, only: :run_query

      # 返回 reports 首页需要的三类报表资源集合。
      def index
        render json: {
          data: {
            queries: serialized_collection(accessible_queries.active),
            dashboards: serialized_collection(accessible_dashboards.active),
            alerts: serialized_collection(accessible_alerts.active)
          }
        }
      end

      # 返回当前用户可读的保存查询列表。
      def queries
        render_collection(accessible_queries.active)
      end

      # 返回指定保存查询配置。
      def show_query
        render_record(accessible_queries.active.find(params.expect(:id)))
      end

      # 执行保存查询并返回二维数据和列元信息。
      def run_query
        query = accessible_queries.active.find(params.expect(:id))

        authorize_embedded_queries!(query)

        query_result = Motor::Queries::RunQuery.call(
          query,
          variables_hash: variables_params,
          limit: params[:limit].presence,
          filters: filter_params
        )

        if query_result.error
          render json: { errors: [{ detail: query_result.error }] }, status: :unprocessable_content
        else
          render json: {
            data: query_result.data,
            meta: { columns: query_result.columns }
          }
        end
      end

      # 返回当前用户可读的仪表盘列表。
      def dashboards
        render_collection(accessible_dashboards.active)
      end

      # 返回指定仪表盘配置。
      def show_dashboard
        render_record(accessible_dashboards.active.find(params.expect(:id)))
      end

      # 返回当前用户可读的告警列表。
      def alerts
        render_collection(accessible_alerts.active)
      end

      # 返回指定告警配置。
      def show_alert
        render_record(accessible_alerts.active.find(params.expect(:id)))
      end

      private

      # 对列表应用 Motor API 查询参数，并输出 data/meta 标准结构。
      def render_collection(relation)
        resources = Motor::ApiQuery.call(relation, params)

        render json: {
          data: serialized_collection(resources),
          meta: Motor::ApiQuery::BuildMeta.call(resources, params)
        }
      end

      # 序列化单条配置记录，字段裁剪仍受 current_ability 控制。
      def render_record(record)
        render json: { data: Motor::ApiQuery::BuildJson.call(record, params, current_ability) }
      end

      # 序列化集合记录，复用 Motor 内部 JSON 构建器。
      def serialized_collection(relation)
        Motor::ApiQuery::BuildJson.call(relation, params, current_ability)
      end

      # 当前用户可访问的保存查询 scope。
      def accessible_queries
        Motor::Query.accessible_by(current_ability)
      end

      # 当前用户可访问的仪表盘 scope。
      def accessible_dashboards
        Motor::Dashboard.accessible_by(current_ability)
      end

      # 当前用户可访问的告警 scope。
      def accessible_alerts
        Motor::Alert.accessible_by(current_ability)
      end

      # 检查 SQL 中引用的 query_N 子查询，避免绕过被引用查询的读取权限。
      def authorize_embedded_queries!(query)
        query.sql_body.to_s.scan(/query_\d+/).each do |name|
          accessible_queries.active.find(name.split('_').last)
        end
      end

      # 合并请求变量和可信的当前用户变量，后者覆盖同名伪造值。
      def variables_params
        request_variables = params.fetch(:variables, {})
        request_variables = request_variables.to_unsafe_h if request_variables.respond_to?(:to_unsafe_h)

        request_variables.merge(current_user_variables)
      end

      # 为 SQL 模板提供 current_user_id/current_user_email 内置变量。
      def current_user_variables
        current_user
          .attributes
          .slice('id', 'email')
          .transform_keys { |key| "current_user_#{key}" }
          .compact
      end

      # 兼容 filter 和 filters 两种查询过滤参数。
      def filter_params
        filters = params[:filter] || params[:filters]

        filters.respond_to?(:to_unsafe_h) ? filters.to_unsafe_h : filters
      end
    end
  end
end
