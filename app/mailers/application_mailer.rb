# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.bibdata['default_sender_email_address']
  layout 'mailer'
end
