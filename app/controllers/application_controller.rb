# frozen_string_literal: true

class ApplicationController < ActionController::API
  def index
    render plain: "#{Rails.application.class.module_parent_name}\nVersion: #{VERSION}"
  end
end
