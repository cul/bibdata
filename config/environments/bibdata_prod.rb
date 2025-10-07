# frozen_string_literal: true

require Rails.root.join('config/environments/deployed.rb')

Rails.application.configure do
  # Using :info level logging during initial deployment.
  # Will eventually change to :error after the process has been running for a while.
  config.log_level = :info

  config.action_mailer.default_url_options = { host: 'lito-rails-prod1.cul.columbia.edu' }
end
