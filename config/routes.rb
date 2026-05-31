# frozen_string_literal: true

Rails.application.routes.draw do
  base_path = ENV.fetch('BASE_PATH', '/admin').presence || '/admin'
  base_path = "/#{base_path}" unless base_path.start_with?('/')
  base_path = base_path.delete_suffix('/') unless base_path == '/'

  root to: redirect(base_path) unless base_path == '/'

  get '/apple-touch-icon.png', to: redirect('/favicon.ico')
  get '/apple-touch-icon-precomposed.png', to: redirect('/favicon.ico')

  devise_for :admin_users, class_name: 'Motor::AdminUser', path: base_path

  resources :impersonate, only: %i[show], param: 'token'

  get "#{base_path}/assets/*filename", to: 'motor/assets#show', as: :motor_asset, format: false

  if base_path != '/'
    get "#{base_path}#{base_path}/settings",
        to: redirect(status: 301) { |_params, _request| "#{base_path}/settings" }

    get "#{base_path}#{base_path}/settings/*settings_path",
        to: redirect(status: 301) { |params, _request| "#{base_path}/settings/#{params[:settings_path]}" }
  end

  scope base_path, as: :admin do
    with_options controller: 'ui' do
      resource :setup, only: %i[show]

      resource :settings, only: %i[show] do
        resource :general, only: %i[show]
        resources :users, only: %i[index]
        resources :roles, only: %i[index]
        resource :database, only: %i[show]
        resource :email, only: %i[show]
        resource :storage, only: %i[show]
        resource :other, only: %i[show]
      end
    end

    namespace :api do
      resource :setup, only: %i[create]
      resource :session, only: %i[destroy]
      resources :verify_db_connection, only: %i[create]
      resources :roles, only: %i[index create update destroy]
      resources :encrypted_configs, only: %i[show index create], param: 'key', constraints: { key: /.+/ }
      resources :admin_users, only: %i[index show create update destroy] do
        post :reset_password
      end
    end
  end

  if ENV['MOTOR_PUBLIC_ACCESS'].to_s == 'true'
    mount Motor::Admin => base_path
  else
    authenticate :admin_user do
      mount Motor::Admin => base_path
    end
  end
end
