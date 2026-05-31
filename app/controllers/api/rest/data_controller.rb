# frozen_string_literal: true

module Api
  module Rest
    # 动态管理数据 REST API，提供通用资源的查询和写入入口。
    class DataController < BaseController
      wrap_parameters :data, except: %i[include fields]

      include Motor::WrapIoParams

      before_action :maybe_set_db_connection_and_define_ar_models

      include Motor::LoadAndAuthorizeDynamicResource

      before_action :wrap_io_params, only: %i[create update]

      # 查询动态资源列表，并复用 Motor 的过滤、排序、分页和字段裁剪逻辑。
      def index
        @resources = Motor::ApiQuery.call(@resources, params)

        render json: {
          data: Motor::ApiQuery::BuildJson.call(@resources, params, current_ability),
          meta: Motor::ApiQuery::BuildMeta.call(@resources, params)
        }
      end

      # 返回单条动态资源记录。
      def show
        render json: { data: Motor::ApiQuery::BuildJson.call(@resource, params, current_ability) }
      end

      # 创建动态资源记录，资源类和权限由 Motor 动态资源 concern 负责加载。
      def create
        @resource.save!

        render json: { data: Motor::ApiQuery::BuildJson.call(@resource, params, current_ability) },
               status: :created
      rescue ActiveRecord::RecordInvalid
        render json: { errors: @resource.errors }, status: :unprocessable_content
      end

      # 更新动态资源记录，字段白名单交给动态模型和 ActiveRecord 校验收口。
      def update
        @resource.update!(resource_params)

        render json: { data: Motor::ApiQuery::BuildJson.call(@resource, params, current_ability) }
      rescue ActiveRecord::RecordInvalid
        render json: { errors: @resource.errors }, status: :unprocessable_content
      end

      # 删除动态资源；优先沿用业务表软删除字段，缺失时再执行物理删除。
      def destroy
        if @resource.respond_to?(:deleted_at)
          @resource.update!(deleted_at: Time.current)
        elsif @resource.respond_to?(:archived_at)
          @resource.update!(archived_at: Time.current)
        else
          @resource.destroy!
        end

        head :ok
      end

      private

      # 提取动态资源写入参数，保留动态字段能力但限制在 data 节点内。
      def resource_params
        return {} if params[:data].blank?

        params.require(:data).permit!
      end
    end
  end
end
