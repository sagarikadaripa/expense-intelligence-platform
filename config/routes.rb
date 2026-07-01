# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  resource :dashboard, only: [:show], controller: "dashboard"
  resources :transactions, only: %i[index create update destroy]
  resource :export, only: [:show], controller: "exports"
  resources :imports, only: %i[create show], controller: "imports"
  resource :profile, only: [:edit, :update]

  namespace :api do
    namespace :v1 do
      resources :upi_transactions, only: [:create]
      post "whatsapp/webhook", to: "whatsapp#webhook"
      resource :dashboard, only: [:show]
    end
  end

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
