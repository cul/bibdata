# config valid only for current version of Capistrano
lock '~> 3.12.0'

set :application, 'bibdata'
set :repo_url, "git@github.com:cul/#{fetch(:application)}.git"

# Default branch is :columbia
# (this is a fork of a Princeton project)
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/opt/#{fetch(:application)}"
# set :repo_path, "/opt/#{fetch(:application)}/repo"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# set :ssh_options, { forward_agent: true }

# Default value for :pty is false
# set :pty, true

set :linked_files, %w{
  config/database.yml 
  config/app_config.yml
  config/secrets.yml
  config/ip_whitelist.yml
  config/cas.yml
}
# CUL - don't symlink these, deploy with repo
#  config/initializers/voyager_helpers.rb
#  config/initializers/devise.rb


# Default value for linked_dirs is []
set :linked_dirs, %w{
  log
  tmp
  vendor/bundle
  public/system
  log
}


# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# can't get "passenger-config restart-app" working
set :passenger_restart_with_touch, true

namespace :deploy do

  # desc "Check that we can access everything"
  # task :check_write_permissions do
  #   on roles(:all) do |host|
  #     if test("[ -w #{fetch(:deploy_to)} ]")
  #       info "#{fetch(:deploy_to)} is writable on #{host}"
  #     else
  #       error "#{fetch(:deploy_to)} is not writable on #{host}"
  #     end
  #   end
  # end

  # desc 'Restart application'
  # task :restart do
  #   on roles(:app), in: :sequence, wait: 5 do
  #     execute :touch, release_path.join('tmp/restart.txt')
  #   end
  # end

  # after :publishing, :restart

  # after :restart, :clear_cache do
  #   on roles(:web), in: :groups, limit: 3, wait: 10 do
  #     # Here we can do anything such as:
  #     # within release_path do
  #     #   execute :rake, 'cache:clear'
  #     # end
  #   end
  # end

  # after :finishing, 'deploy:cleanup'

end
