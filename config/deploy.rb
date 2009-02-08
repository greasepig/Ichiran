set :application, "ichiran"
set :scm, :git
set :repository,  "http://mossg.com/ichiran.git"
set :branch, "master"
set :deploy_via, :remote_cache

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/greasepig/ichiran"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "mossg.com"
role :web, "mossg.com"
role :db,  "mossg.com", :primary => true

set :user, "greasepig"
set :use_sudo, false

namespace :deploy do
  desc "Restarting rails by killing dispatch.fcgi"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "/usr/bin/killall -q -USR1 dispatch.fcgi"
  end
 
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op for this case"
    task t, :roles => :app do ; end
  end
end
desc "Move files after deployment"
task :move_files do
    run "cp #{deploy_to}/current/tmp/.htaccess  #{deploy_to}/current/public/.htaccess" 
    run "ln -s /home/greasepig/ichiran/current/public /home/greasepig/daikoke.com/ichiran" 
    run "ln -s /home/greasepig/ichiran/shared/production.sqlite3 /home/greasepig/ichiran/current/db/production.sqlite3" 
end
after :deploy, :move_files
after :deploy, "deploy:migrate"
