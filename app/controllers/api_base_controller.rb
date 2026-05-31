# frozen_string_literal: true

class ApiBaseController < ActionController::API
  unless Rails.env.test?
    rescue_from StandardError do |e|
      Rails.logger.error(e)
      Rails.logger.error(e.backtrace.join("\n"))

      render json: { errors: [e.message] }, status: :internal_server_error
    end

    rescue_from CanCan::AccessDenied do |e|
      Rails.logger.error(e)

      message =
        if params[:action].in?(%w[create update destroy])
          I18n.t('motor.not_authorized_to_perform_action')
        else
          e.message
        end

      render json: { errors: [message] }, status: :forbidden
    end
  end

  def current_ability
    Motor::Ability.new(current_admin_user, request)
  end
end
