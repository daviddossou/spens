Rails.application.routes.draw do
  # Locale support - wrap routes in scope for i18n
  scope "(:locale)", locale: /en|fr/ do
    devise_for :users, controllers: {
      registrations: 'users/registrations'
    }

    # Main application routes
    root "home#index"
    get "dashboard", to: "home#dashboard"
  end

  # Sidekiq web interface (only in development)
  if Rails.env.development?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  # Health check and PWA routes (outside locale scope)
  get "up" => "rails/health#show", as: :rails_health_check
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
