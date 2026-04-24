# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

require File.expand_path('../config/environment', __dir__)

set :environment, Rails.env

# Log cron output to app log directory
set :output, Rails.root.join("log/#{Rails.env}_cron_log.log")

set :email_subject, 'Bibdata Cron Error (via Whenever Gem)'
set :error_recipient, Rails.configuration.bibdata[:developer_email_address]
set :job_template, "/usr/local/bin/mailifrc -s 'Error - :email_subject' :error_recipient -- /bin/bash -l -c ':job'"

job_type :rake, 'cd :path && :environment_variable=:environment bundle exec rake :task --silent :output'

if Rails.env.bibdata_prod? || Rails.env.bibdata_test? || Rails.env.bibdata_dev? # rubocop:disable Rails/UnknownEnv
  # Email today's aggregated errors, if there are any
  every 1.day, at: '8:00 pm' do
    rake 'bibdata:process_daily_errors:email_barcode_update_errors'
  end
end
