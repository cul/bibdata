# frozen_string_literal: true

Rails.application.routes.draw do
  # TODO: Eventually remove this route once we cut over to using the two routes below
  get 'barcode/:barcode' => 'barcode#query'

  get 'barcode/:barcode/query' => 'barcode#query'
  post 'barcode/:barcode/update' => 'barcode#update'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'application#index'
end
