# frozen_string_literal: true

class ApiController < ActionController::API
  # Unlike ActionController::Base, ActionController::API does not include token HttpAuthentication Token
  # methods by default, so we'll include it.
  include ActionController::HttpAuthentication::Token::ControllerMethods
end
