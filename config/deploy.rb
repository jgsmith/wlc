default_run_options[:pty] = true

set :application, "wlc"
set :repository,  "git://github.com/jgsmith/wlc.git"
set :scm, "git"
set :branch, "master"
set :scm_verbose, true
set :deploy_via, :remote_cache


# If you have previously been relying upon the code to start, stop 
# and restart your mongrel application, or if you rely on the database
# migration code, please uncomment the lines you require below

# If you are deploying a rails app you probably need these:

# load 'ext/rails-database-migrations.rb'
# load 'ext/rails-shared-directories.rb'

# There are also new utility libaries shipped with the core these 
# include the following, please see individual files for more
# documentation, or run `cap -vT` with the following lines commented
# out to see what they make available.

# load 'ext/spinner.rb'              # Designed for use with script/spin
# load 'ext/passenger-mod-rails.rb'  # Restart task for use with mod_rails
# load 'ext/web-disable-enable.rb'   # Gives you web:disable and web:enable

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"
set :deploy_to, "/usr/local/www/deploy/#{application}"
set :user, "deploy"
set :spinner_user, "www"
set :start_port, 3200
set :instances, 3

set :use_sudo, false

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
# see a full list by running "gem contents capistrano | grep 'scm/'"

role :web, "it-wlc.local"
role :app, "it-wlc.local"
role :db,  "it-wlc.local"


namespace :deploy do
  desc "Capfile override of the default restart task to eliminate reaper"
  task :restart, :roles => :app do
    run "/usr/local/bin/sudo /usr/local/etc/rc.d/lighttpd reload"
  end

  task :start, :roles => :app do
    run "/usr/local/bin/sudo /usr/local/etc/rc.d/lighttpd restart"
  end
end

namespace :local_deploy do
  desc "Make sure current/tmp points to shared/tmp"
  task :deploy_tmp, :roles => :app do
    [ 'tmp', 'uploads', 'temp_files' ].each do |dir|
      run "if [ ! -L #{release_path}/#{dir} ]; then rm -rf #{release_path}/#{dir}; ln -s #{deploy_to}/shared/#{dir} #{release_path}/#{dir}; fi"
    end
  end

  desc "Make sure shared/tmp exists"
  task :setup_tmp, :roles => :app do
    [ 'tmp', 'uploads', 'temp_files' ].each do |dir|
      run "if [ ! -d #{deploy_to}/shared/#{dir} ]; then mkdir #{deploy_to}/shared/#{dir}; fi"
    end
  end
end

after "deploy:update_code", "local_deploy:deploy_tmp"
after "deploy:setup", "local_deploy:setup_tmp"
