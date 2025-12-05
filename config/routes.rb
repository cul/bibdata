# frozen_string_literal: true

require 'resque/server'

Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: 'users/sessions', omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    get '/users/sign_in', to: 'users/sessions#new'
    delete '/users/sign_out', to: 'users/sessions#destroy'
  end

  get 'barcode/:barcode/query' => 'barcode#query'
  post 'barcode/:barcode/update' => 'barcode#update'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'pages#home'

  # Make sure that the resque user restriction below is AFTER `devise_for :users`
  resque_web_constraint = lambda do |request|
    current_user = request.env['warden'].user
    current_user.present? && current_user.respond_to?(:admin?) && current_user.admin?
    true
  end
  constraints resque_web_constraint do
    mount Resque::Server.new, at: '/resque'
  end
end
