# frozen_string_literal: true

module Motor
  # 数据库配置工具，统一清洗连接 URL、演示库路径和已保存的数据库配置。
  module DatabaseConfigs
    DEMO_DATABASE_FILENAME = 'motor-admin-demo.sqlite3'
    SQLITE_DATABASE_FILENAME = 'database.sqlite3'
    SUPPORTED_DATABASE_URL_SCHEMES = %w[mysql mysql2 postgres postgresql sqlserver].freeze
    NORMALIZED_DATABASE_URL_SCHEMES = {
      'mysql' => 'mysql2',
      'postgresql' => 'postgres'
    }.freeze
    POSTGRES_SCHEMA_NAME_PATTERN = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
    MALFORMED_PERCENT_ENCODING_PATTERN = /%(?![0-9A-Fa-f]{2})/
    INVALID_SCHEMA_SEARCH_PATH_MESSAGE =
      'schema_search_path can only include comma-separated PostgreSQL schema names'
    DUPLICATE_DATABASE_NAME_MESSAGE = 'database config names must be unique'
    UNSUPPORTED_DATABASE_URL_MESSAGE = 'database config urls must use postgres, mysql, or sqlserver'

    module_function

    # 读取已保存数据库配置并统一归一化。
    def configured_entries
      config = Motor::EncryptedConfig.find_by(key: Motor::EncryptedConfig::DATABASE_CREDENTIALS_KEY)

      normalized_entries(config&.value)
    end

    # 归一化一组数据库配置，丢弃无效项。
    def normalized_entries(entries)
      Array.wrap(entries).filter_map { |entry| normalize_entry(entry) }
    end

    # 清理数据库配置名称。
    def normalize_name(name)
      name.to_s.strip.presence
    end

    # 清理数据库 URL，并把 mysql/postgresql scheme 映射为适配器使用的标准 scheme。
    def normalize_url(url)
      url = url.to_s.strip

      return if url.blank?

      scheme = database_url_scheme(url)

      return unless supported_database_url_scheme?(scheme)

      normalized_scheme = NORMALIZED_DATABASE_URL_SCHEMES.fetch(scheme.downcase, scheme.downcase)

      url.sub(/\A#{Regexp.escape(scheme)}(?=:)/i, normalized_scheme)
    end

    # 判断数据库 URL 是否使用支持的 scheme。
    def supported_database_url?(url)
      normalize_url(url).present?
    end

    # 判断数据库 URL 是否完整可解析且没有非法百分号编码。
    def valid_database_url?(url)
      normalized_url = normalize_url(url)

      return false if normalized_url.blank?
      return false if malformed_percent_encoding?(normalized_url)

      URI.parse(normalized_url)

      true
    rescue URI::InvalidURIError
      false
    end

    # 检查字符串中是否包含不完整的百分号转义。
    def malformed_percent_encoding?(value)
      value.to_s.match?(MALFORMED_PERCENT_ENCODING_PATTERN)
    end

    # 判断数据库 URL scheme 是否在支持列表中。
    def supported_database_url_scheme?(scheme)
      SUPPORTED_DATABASE_URL_SCHEMES.include?(scheme.to_s.downcase)
    end

    # 从 URL 字符串中提取 scheme。
    def database_url_scheme(url)
      url.to_s.strip[%r{\A([^:]+)://}, 1]
    end

    # 将配置名称转换为动态连接类名。
    def connection_class_name(name)
      class_name = normalize_name(name).to_s.sub(/\A\d+/, '').parameterize.underscore.classify

      class_name.presence || 'Database'
    end

    # 判断配置名称是否代表默认 ResourceRecord 连接。
    def default_connection_name?(name)
      normalize_name(name).to_s.casecmp?('default')
    end

    # 归一化 PostgreSQL schema_search_path，拒绝非 schema 名称字符。
    def normalize_schema_search_path(schema_search_path)
      schemas = schema_search_path.to_s.split(',').map(&:strip).compact_blank

      return if schemas.blank?
      return unless schemas.all? { |schema| schema.match?(POSTGRES_SCHEMA_NAME_PATTERN) }

      schemas.join(',')
    end

    # 判断 schema_search_path 是否为空或合法。
    def valid_schema_search_path?(schema_search_path)
      schema_search_path.blank? || normalize_schema_search_path(schema_search_path).present?
    end

    # 返回演示 SQLite 连接配置。
    def demo_connection_config
      { adapter: :sqlite3, database: demo_database_path }
    end

    # 生成连接签名，用于判断是否需要重连。
    def connection_signature(entry)
      [entry['url'].to_s, normalize_schema_search_path(entry['schema_search_path']).to_s]
    end

    # 判断现有连接是否与配置 URL 和 schema_search_path 一致。
    def connection_matches?(base_class, entry)
      base_class.connection_db_config.try(:url) == entry['url'] &&
        schema_search_path_matches?(base_class.connection, entry['schema_search_path'])
    end

    # 对 PostgreSQL 连接应用 schema_search_path，并在变更后清理 schema cache。
    def apply_schema_search_path(base_class, schema_search_path)
      connection = base_class.connection
      schema_search_path = normalize_schema_search_path(schema_search_path)

      return if schema_search_path.blank?
      return unless connection.respond_to?(:schema_search_path=)
      return if schema_search_path_matches?(connection, schema_search_path)

      connection.schema_search_path = schema_search_path
      connection.schema_cache.clear!
    end

    # 定位演示数据库；工作目录没有 database.sqlite3 时复制到 /tmp。
    def demo_database_path
      candidate_path = Pathname(ENV['WORKDIR'].presence || Rails.root).join(SQLITE_DATABASE_FILENAME)

      return candidate_path.to_s if candidate_path.exist?

      fallback_path = Pathname('/tmp').join(DEMO_DATABASE_FILENAME)

      copy_demo_database(fallback_path)

      fallback_path.to_s
    end

    # 归一化单条数据库配置，字段缺失或 schema 不安全时丢弃。
    def normalize_entry(entry)
      return unless entry.respond_to?(:to_h)

      entry = entry.to_h.with_indifferent_access
      name = normalize_name(entry[:name])
      url = normalize_url(entry[:url])
      schema_search_path = normalize_schema_search_path(entry[:schema_search_path])

      return if name.blank? || url.blank?
      return if entry[:schema_search_path].present? && schema_search_path.blank?

      {
        'name' => name,
        'url' => url,
        'schema_search_path' => schema_search_path
      }.compact
    end

    # 并发安全地复制演示库到目标路径。
    def copy_demo_database(target_path)
      return if target_path.exist?

      source_path = Rails.root.join(DEMO_DATABASE_FILENAME)
      temp_path = target_path.dirname.join(".#{target_path.basename}.#{$PROCESS_ID}.#{Thread.current.object_id}.tmp")

      # 演示库只在本地 fallback 时复制一次，用临时文件和硬链接避免并发请求读到半写入文件。
      temp_path.binwrite(source_path.binread)
      File.link(temp_path, target_path)
    rescue Errno::EEXIST
      nil
    ensure
      temp_path&.delete if temp_path&.exist?
    end

    # 判断连接当前 schema_search_path 是否与目标配置一致。
    def schema_search_path_matches?(connection, schema_search_path)
      schema_search_path = normalize_schema_search_path(schema_search_path)

      return true if schema_search_path.blank?
      return true unless connection.respond_to?(:schema_search_path)

      connection.schema_search_path.to_s == schema_search_path.to_s
    end
  end
end
