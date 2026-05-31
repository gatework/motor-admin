# frozen_string_literal: true

module Api
  class SetupsController < ApiBaseController
    class AlreadySetupError < StandardError
    end

    skip_authorization_check

    def create
      raise AlreadySetupError if Motor::AdminUser.any?

      user = Motor::AdminUser.new(admin_user_params.merge(roles: [Motor::Role.superadmin]))

      if user.save
        sign_in(user)

        render json: { data: user.as_json }
      else
        render json: { errors: user.errors.as_json }, status: :unprocessable_content
      end
    end

    private

    def admin_user_params
      params.expect(admin_user: %i[first_name last_name email password])
    end
  end
end
