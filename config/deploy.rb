# frozen_string_literal: true

# config valid for current version and patch releases of Capistrano
lock '~> 3.19.2'

set :rvm_custom_path, '~/.rvm'

set :remote_user, 'litoserv'
set :application, 'bibdata'
set :repo_name, fetch(:application)
set :repo_url, "git@github.com:cul/#{fetch(:repo_name)}.git"
set :deploy_name, "#{fetch(:application)}_#{fetch(:stage)}" # e.g. bibdata_dev

# Used to run rake db:migrate, etc.
# Keeps things in sync...
# Rails env is used by Rails at runtime. Determines, e.g., which db is used,
# which gems are included in the app (will match :development, :test, etc.)
set :rails_env, fetch(:deploy_name)

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/opt/passenger/#{fetch(:deploy_name)}"

# Default value for :linked_files is []
append  :linked_files,
        # 'config/database.yml',
        'config/folio.yml',
        'config/master.key' # we don't use this often, when we do it is for API keys

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'node_modules'
# Capi will create symlinks to the linked_files and linked_dirs so that we can load
# in config values without committing them to repo + these files can be shared across
# deployments. They will actually exist inside the 'shared directory'

# Configure capistrano/passenger to use touch method to restart workers
set :passenger_restart_with_touch, true

# Default value for keep_releases is 5
set :keep_releases, 3

# Set default log level (which can be overridden by other environments), default is :debug
set :log_level, :info

# NVM Setup, for selecting the correct node version
# NOTE: This NVM configuration MUST be configured before the RVM setup steps because:
# This works:
# nvm exec 16 ~/.rvm-alma8/bin/rvm example_app_dev do node --version
# But this does not work:
# ~/.rvm-alma8/bin/rvm example_app_dev do nvm exec 16 node --version
# NO js frontend in this api... comment out next four
# NOTE: rake is sometimes used to run tasks that execute other node commands
# set :nvm_node_version, fetch(:deploy_name) # This NVM alias must exist on the server
# [:rake, :node, :npm, :yarn].each do |command_to_prefix|
#   # Prefix all node-related commands with this string that specifies the node version to use
#   SSHKit.config.command_map.prefix[command_to_prefix].push("nvm exec #{fetch(:nvm_node_version)}")
# end

# RVM Setup, for selecting the correct ruby version (instead of capistrano-rvm gem)
set :rvm_ruby_version, fetch(:deploy_name) # This RVM alias must exist on the server
[:rake, :gem, :bundle, :ruby].each do |command_to_prefix|
  SSHKit.config.command_map.prefix[command_to_prefix].push(
    "#{fetch(:rvm_custom_path, '~/.rvm')}/bin/rvm #{fetch(:rvm_ruby_version)} do"
  )
end

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
