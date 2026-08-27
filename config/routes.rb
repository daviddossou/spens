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

    # Device time zone capture (JS posts the IANA zone when it changes)
    patch "time_zone", to: "users/time_zones#update", as: :time_zone

    # Main application routes
    root "home#index"
    get "welcome", to: "landing#show", as: :landing
    get "privacy", to: "legal#privacy", as: :privacy
    get "terms", to: "legal#terms", as: :terms
    get "dashboard", to: "home#show"

    # Transactions
    resources :transactions, only: [ :new, :create, :show, :edit, :update, :destroy ]

    # Quick add: parse one natural-language utterance into a transaction (typed now, voice later)
    resource :quick_entry, only: [ :new, :create ]

    # Goals
    resources :goals, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]

    # Debts
    resources :debts, only: [ :index, :show, :new, :create, :edit, :update ] do
      member { post :write_off, to: "debts/write_offs#create" }
    end

    # Accounts
    resources :accounts, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]

    # Monthly budget (forecast + past-month summary), its recurring items and per-month entries
    resources :budgets, only: [ :index ] do
      # The finished-month view is now the Budget page in Bilan mode; the old
      # /summary URL redirects to the same month on index (see controller).
      collection { get :summary }
    end
    resources :budget_items, only: [ :new, :create, :edit, :update, :destroy ]
    resources :budget_entries, only: [ :edit, :update ]

    # Spaces
    resources :spaces, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      resource :selection, only: :create, module: :spaces
      resources :members, only: [ :index, :new, :create ], module: :spaces
      # The space's learned vocabulary (personal category/kind mappings)
      resources :mappings, only: [ :index, :update, :destroy ], module: :spaces
    end

    # Invitations (accept flow only — creating invitations goes through spaces/members)
    resources :invitations, only: []
    get "invitations/:token/accept", to: "invitations#show", as: :accept_invitation

    # Analytics
    get "analytics", to: "analytics#index", as: :analytics

    # Admin area (gated by Admin::BaseController; not space-scoped)
    namespace :admin do
      root "dashboard#show"

      resources :learned_aliases, only: [ :index, :create ] do
        member { patch :approve; patch :reject; patch :restore; patch :reassign }
      end
      resources :learned_keywords, only: :index do
        member { patch :approve; patch :reject; patch :restore }
      end
      resources :corrections, only: :index do
        member { post :teach; patch :dismiss }
      end
      resources :category_gaps, only: :index do
        collection { post :map; post :dismiss }
      end
      resources :taxonomy_nodes, except: :show do
        member { patch :activate; patch :deactivate; patch :move_up; patch :move_down; patch :rename }
        collection { patch :reorder }
      end

      resources :users, only: [ :index, :show ] do
        member do
          post :impersonate
          patch :grant_admin
          patch :revoke_admin
        end
      end

      resources :spaces, only: [ :index, :show ]
      resources :transactions, only: :index
      resources :quick_entry_attempts, only: :index
      resources :audit_logs, only: :index
    end

    # Stop impersonating — OUTSIDE the admin gate, since current_user is the impersonated
    # (non-admin) user mid-impersonation. Guarded by the true-admin id stashed in the session.
    delete "stop_impersonating", to: "impersonations#destroy", as: :stop_impersonating

    # Onboarding routes
    get "onboarding", to: "onboarding#show"

    namespace :onboarding do
      resource :financial_goals, only: [ :show, :update ]
      resource :profile_setups, only: [ :show, :update ]
      resource :account_setups, only: [ :show, :update ]
    end
  end

  # Solid Errors dashboard — admin-only, outside the locale scope (engine paths aren't localized).
  # Warden-level gate; mid-impersonation the current user is the (non-admin) target, so it stays shut.
  authenticate :user, ->(user) { user.admin? } do
    mount SolidErrors::Engine, at: "/admin/errors"
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
