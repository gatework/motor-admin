# frozen_string_literal: true

require 'json'
require 'optparse'
require_relative 'authorization_token'

module Motor
  module AuthorizationCli
    FORMATS = %w[header token json].freeze

    module_function

    def generate(argv)
      options = parse_options(argv)
      admin_user = find_admin_user(options)
      issued_at = Time.current
      token = Motor::AuthorizationToken.encode(admin_user, expires_in: options[:ttl], issued_at: issued_at)

      print_token(token, admin_user, options, issued_at)
    rescue OptionParser::ParseError, ActiveRecord::RecordNotFound, ArgumentError, RuntimeError => e
      warn e.message
      warn
      warn parser
      exit 1
    end

    def parse_options(argv)
      options = {
        format: 'header',
        ttl: Motor::AuthorizationToken::DEFAULT_TTL
      }

      parser(options).parse!(argv)

      options
    end

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

    def find_admin_user(options)
      if options[:id]
        Motor::AdminUser.find(options[:id])
      elsif options[:email].present?
        Motor::AdminUser.find_by!(email: options[:email])
      else
        raise ArgumentError, 'Specify --email or --id'
      end
    end

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

    def parse_duration(value)
      match = value.to_s.strip.match(/\A(\d+)([smhd])?\z/)
      raise ArgumentError, "Invalid ttl: #{value.inspect}" unless match

      amount = match[1].to_i

      case match[2]
      when 's', nil then amount.seconds
      when 'm' then amount.minutes
      when 'h' then amount.hours
      when 'd' then amount.days
      end
    end
  end
end
