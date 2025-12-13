source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# For ActiveRecord, mysql for deployed server databases
gem 'mysql2', '~> 0.5.6'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

# ruby-marc library [https://github.com/ruby-marc/ruby-marc]
gem "marc", "~> 1.3"

gem 'nokogiri', '~> 1.18', '>= 1.18.10', force_ruby_platform: true

# Rainbow for text coloring
gem "rainbow", "~> 3.0"

# Retriable for retrying operations in response to specific exceptions
gem 'retriable', '~> 3.1'

# Resque/Redis (for queued jobs)
gem 'redis', '~> 4.8' # NOTE: Updating the redis gem to v5 breaks the current redis namespace setup
gem 'redis-namespace', '~> 1.11'
gem 'resque', '~> 2.6'

# For authentication
gem 'devise', '~> 4.9'
gem 'omniauth', '~> 2.1'
gem 'omniauth-rails_csrf_protection', '~> 2.0'
# gem 'omniauth-cul', '~> 0.2.0'
gem 'omniauth-cul', git: 'https://github.com/cul/omniauth-cul', ref: 'improved-implementation'

# FOLIO Client
gem "folio_api_client", "~> 0.5.0"
# gem "folio_api_client", path: "../folio_api_client"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # rubocop + CUL presets
  gem 'rubocul', '~> 4.0.12'

  gem "rspec-rails", "~> 8.0"

  gem "simplecov", require: false

  # For ActiveRecord, use sqlite for dev/test databases and mysql for deployed server databases
  gem 'sqlite3', '~> 2.8'
end

group :development do
  # Capistrano for deployment (per https://capistranorb.com/documentation/getting-started/installation/)
  gem "capistrano", "~> 3.19.2", require: false
  gem "capistrano-cul", require: false # common set of tasks shared across cul apps
  gem "capistrano-rails", "~> 1.4", require: false # for compiling rails assets
  gem "capistrano-passenger", "~> 0.1", require: false # allows restart passenger workers
end
