Rails.application.routes.draw do
  # Register Devise user mapping for Warden session management (no routes generated)
  devise_for :users, skip: :all

  # Locale support - wrap routes in scope for i18n
  scope "(:locale)", locale: /en|fr/ do
    # Passwordless auth routes (within devise_scope for Warden integration)
    devise_scope :user do
      get "sign_in", to: "auth/sessions#new", as: :new_user_session
      post "sign_in", to: "auth/sessions#create", as: :user_session
      delete "sign_out", to: "auth/sessions#destroy", as: :destroy_user_session

      get "sign_up", to: "auth/registrations#new", as: :new_user_registration
      post "sign_up", to: "auth/registrations#create", as: :user_registration

      get "verify", to: "auth/verifications#show", as: :auth_verification
      post "verify", to: "auth/verifications#create"
      post "verify/resend", to: "auth/verifications#resend", as: :resend_otp
    end

    # Profile management
    get "profile/edit", to: "users/profile#edit", as: :edit_profile
    patch "profile", to: "users/profile#update", as: :profile
    put "profile", to: "users/profile#update"
    delete "profile", to: "users/profile#destroy"

    # Main application routes
    root "home#index"
    get "dashboard", to: "home#show"

    # Transactions
    resources :transactions, only: [ :new, :create, :show, :edit, :update, :destroy ]

    # Goals
    resources :goals, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]

    # Debts
    resources :debts, only: [ :index, :show, :new, :create, :edit, :update ]

    # Accounts
    resources :accounts, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]

    # Spaces
    resources :spaces, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      resource :selection, only: :create, module: :spaces
      resources :members, only: [ :index, :new, :create ], module: :spaces
    end

    # Invitations (accept flow only — creating invitations goes through spaces/members)
    resources :invitations, only: []
    get "invitations/:token/accept", to: "invitations#show", as: :accept_invitation

    # Analytics
    get "analytics", to: "analytics#index", as: :analytics

    # Onboarding routes
    get "onboarding", to: "onboarding#show"

    namespace :onboarding do
      resource :financial_goals, only: [ :show, :update ]
      resource :profile_setups, only: [ :show, :update ]
      resource :account_setups, only: [ :show, :update ]
    end
  end

  # Sidekiq web interface (only in development)
  if Rails.env.development?
    require "sidekiq/web"
    mount Sidekiq::Web => "/sidekiq"
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Health check and PWA routes (outside locale scope)
  get "up" => "rails/health#show", as: :rails_health_check

  # Turbo Native path configuration — fetched by the Android/iOS app at boot
  get ".well-known/turbo/native-path-configuration",
      to: "path_configuration#show",
      defaults: { format: :json },
      as: :turbo_native_path_configuration
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
