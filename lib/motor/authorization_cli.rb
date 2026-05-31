# frozen_string_literal: true

require 'json'
require 'optparse'
require_relative 'authorization_token'

module Motor
  # 管理后台授权命令，负责按用户身份生成 API Bearer Token。
  module AuthorizationCli
    FORMATS = %w[header token json].freeze

    module_function

    # 解析 CLI 参数、查找管理员并输出对应格式的 token。
    def generate(argv)
      options = parse_options(argv)
      admin_user = find_admin_user(options)
      issued_at = Time.current
      token = Motor::AuthorizationToken.encode(admin_user, expires_in: options[:ttl], issued_at: issued_at)

      print_token(token, admin_user, options, issued_at)
    rescue OptionParser::ParseError, ActiveRecord::RecordNotFound, ArgumentError,
           Motor::AuthorizationToken::ConfigurationError => e
      abort_with_error(e)
    end

    # 输出错误和帮助信息后以非零状态退出。
    def abort_with_error(error)
      warn error.message
      warn
      warn parser

      raise SystemExit, 1
    end

    # 解析命令行参数并填充默认输出格式和 TTL。
    def parse_options(argv)
      options = {
        format: 'header',
        ttl: Motor::AuthorizationToken::DEFAULT_TTL
      }

      parser(options).parse!(argv)

      options
    end

    # 构造 OptionParser，支持 email/id、TTL 和输出格式选项。
    def parser(options = {})
      OptionParser.new do |opts|
        opts.banner = 'Usage: bin/motor-admin auth --email EMAIL [options]'

        opts.on('--email EMAIL', 'Motor admin user email') { |value| options[:email] = value }
        opts.on('--id ID', Integer, 'Motor admin user id') { |value| options[:id] = value }
        opts.on('--ttl DURATION', 'Token lifetime: 900s, 15m, 2h, 7d') do |value|
          options[:ttl] = parse_duration(value)
        end
        opts.on('--format FORMAT', FORMATS, 'Output format: header, token, json') { |value| options[:format] = value }
        opts.on('--token', 'Print only the raw JWT') { options[:format] = 'token' }
        opts.on('--json', 'Print JSON payload') { options[:format] = 'json' }
      end
    end

    # 按 id 或 email 查找活跃管理员，并拒绝锁定账号。
    def find_admin_user(options)
      admin_user =
        if options[:id]
          Motor::AdminUser.active.find(options[:id])
        elsif options[:email].present?
          Motor::AdminUser.active.find_by!(email: options[:email])
        else
          raise ArgumentError, 'Specify --email or --id'
        end

      if admin_user.respond_to?(:access_locked?) && admin_user.access_locked?
        raise ArgumentError, 'Admin user is locked'
      end

      admin_user
    end

    # 根据格式输出原始 token、Authorization 头或 JSON 元信息。
    def print_token(token, admin_user, options, issued_at)
      expires_at = issued_at + options[:ttl]

      case options[:format]
      when 'token'
        puts token
      when 'json'
        puts JSON.pretty_generate(
          token: token,
          token_type: 'Bearer',
          authorization: "Bearer #{token}",
          expires_at: expires_at.iso8601,
          admin_user: {
            id: admin_user.id,
            email: admin_user.email
          }
        )
      else
        puts "Authorization: Bearer #{token}"
      end
    end

    # 解析 900s/15m/2h/7d 形式的 TTL 字符串。
    def parse_duration(value)
      match = value.to_s.strip.match(/\A(\d+)([smhd])?\z/)
      raise ArgumentError, "Invalid ttl: #{value.inspect}" unless match

      amount = match[1].to_i
      raise ArgumentError, "Invalid ttl: #{value.inspect}" unless amount.positive?

      case match[2]
      when 's', nil then amount.seconds
      when 'm' then amount.minutes
      when 'h' then amount.hours
      when 'd' then amount.days
      end
    end
  end
end
