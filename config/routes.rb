Rails.application.routes.draw do
  resource :session
  resource :profile, only: [ :show, :update ]
  resources :passwords, param: :token
  resources :companies, only: [ :index, :new, :create, :edit, :update, :destroy ]
  resources :tasks, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    member do
      patch :deliver
      patch :reopen
      get :reopen_modal
    end
    resources :task_items, only: [ :new, :create, :update, :destroy ]
  end
  resources :projects, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    collection do
      get :projects, to: "projects#projects_json", defaults: { format: :json }
    end
  end

  get "resumo-diario", to: "daily_summary#index", as: :daily_summary

  # Disabled public signup (single-user system)
  get  "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  # OAuth (story 9.1 — DM-008): callback do Google OmniAuth
  match "/auth/:provider/callback", to: "omniauth_callbacks#google_oauth2",
        via: [ :get, :post ],
        as: :omniauth_callback,
        constraints: { provider: "google_oauth2" }
  get "/auth/failure", to: "omniauth_callbacks#failure", as: :omniauth_failure
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"
end
