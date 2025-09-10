# frozen_string_literal: true

class ApplicationController < ActionController::API
  # Unlike ActionController::Base, ActionController::API does not include token HttpAuthentication Token
  # methods by default, so we'll include it.
  include ActionController::HttpAuthentication::Token::ControllerMethods

  def index
    render plain: "#{Rails.application.class.module_parent_name}\nVersion: #{VERSION}"
  end
end
