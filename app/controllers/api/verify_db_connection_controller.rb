# frozen_string_literal: true

module Api
  # 数据库连接验证 API，在保存配置前用目标驱动测试连接可用性。
  class VerifyDbConnectionController < ApiBaseController
    class InvalidUrl < StandardError; end

    CONNECTION_TIMEOUT_SECONDS = 5

    rescue_from InvalidUrl, PG::Error, Mysql2::Error, TinyTds::Error, with: :render_invalid_url

    # 校验 schema_search_path 并尝试建立目标数据库连接。
    def create
      authorize!(:manage, :all)

      url = params.expect(:url).to_s

      validate_schema_search_path!(params[:schema_search_path])
      verify_db_connection!(url)

      head :ok
    end

    private

    # 按 URL scheme 选择对应驱动，并设置短超时避免请求阻塞。
    def verify_db_connection!(url)
      url = normalized_url!(url)
      uri = parse_uri(url)
      scheme = uri.scheme.to_s.downcase

      if scheme.in?(%w[postgres postgresql])
        PG.connect(uri_with_query_value(uri, 'connect_timeout', CONNECTION_TIMEOUT_SECONDS)).close
      elsif scheme == 'sqlserver'
        TinyTds::Client.new(parse_options(uri).merge(login_timeout: CONNECTION_TIMEOUT_SECONDS,
                                                     timeout: CONNECTION_TIMEOUT_SECONDS)).close
      elsif scheme.in?(%w[mysql mysql2])
        Mysql2::Client.new(parse_options(uri).merge(connect_timeout: CONNECTION_TIMEOUT_SECONDS,
                                                    read_timeout: CONNECTION_TIMEOUT_SECONDS,
                                                    write_timeout: CONNECTION_TIMEOUT_SECONDS)).close
      else
        raise InvalidUrl, 'Database URL is invalid'
      end
    end

    # 在连接数据库前校验 PostgreSQL schema 搜索路径格式。
    def validate_schema_search_path!(schema_search_path)
      return if Motor::DatabaseConfigs.valid_schema_search_path?(schema_search_path)

      raise InvalidUrl, Motor::DatabaseConfigs::INVALID_SCHEMA_SEARCH_PATH_MESSAGE
    end

    # 从 URI 中提取通用连接参数。
    def parse_options(uri)
      {
        username: decoded_uri_component(uri.user),
        host: uri.host,
        password: decoded_uri_component(uri.password),
        port: uri.port,
        database: decoded_uri_component(uri.path.delete_prefix('/'))
      }
    end

    # 归一化并校验数据库 URL。
    def normalized_url!(url)
      Motor::DatabaseConfigs.normalize_url(url) || raise(InvalidUrl, 'Database URL is invalid')
    end

    # 解码 URI 组件，保留未编码加号并捕获非法转义。
    def decoded_uri_component(value)
      URI.decode_uri_component(value.to_s) if value
    rescue ArgumentError
      raise InvalidUrl, 'Database URL is invalid'
    end

    # 设置或覆盖查询参数中的超时值。
    def uri_with_query_value(uri, key, value)
      query_values = URI.decode_www_form(uri.query.to_s).reject { |item_key, _| item_key == key }
      query_values << [key, value.to_s]

      uri.dup.tap { |target_uri| target_uri.query = URI.encode_www_form(query_values) }.to_s
    rescue ArgumentError
      raise InvalidUrl, 'Database URL is invalid'
    end

    # 解析 URL，并在 URI.parse 前拒绝明显错误的百分号编码。
    def parse_uri(url)
      raise InvalidUrl, 'Database URL is invalid' if Motor::DatabaseConfigs.malformed_percent_encoding?(url)

      URI.parse(url)
    rescue URI::InvalidURIError
      raise InvalidUrl, 'Database URL is invalid'
    end

    # 返回连接校验失败的统一错误格式。
    def render_invalid_url(error)
      render json: { errors: [error.message] }, status: :unprocessable_content
    end
  end
end
