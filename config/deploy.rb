#require 'capistrano/ext/multistage'
default_run_options[:pty] = true

set :application, "1kg"
set :user, "jill"
set :repository, "git://github.com/Suave/1kg.org.git"
set :scm, :git

role :app, "1kg.org", :primary => true
role :web, "1kg.org"
role :db, "1kg.org", :primary => true

namespace :deploy do
  set :deploy_to, "/home/jill/master"  
  
  desc "Custom after update code to put production database.yml in place."
  task :copy_configs, :roles => :app do
    run "cp #{deploy_to}/shared/database.yml #{current_path}/config/database.yml"
    run "ln -s #{deploy_to}/shared/photos #{current_path}/public/photos"
    run "rm -rf #{current_path}/public/user && ln -s #{deploy_to}/shared/user #{current_path}/public/user"
    run "rm -rf #{current_path}/public/group && ln -s #{deploy_to}/shared/group #{deploy_to}/current/public/group"
    run "cd #{current_path} && rake schools:to_json"
  end
  
  desc "Deploy to dev server"
  task :dev do
    # put up the maintenance screen
    # ENV['REASON'] = 'an application upgrade'
    # ENV['UNTIL']  = Time.now.+(600).strftime("%H:%M %Z")
    # web.disable
    set :deploy_to, "/home/jill/dev"
    set :branch, "dev"
    set :env, "production"
    
    transaction do
      update_code
      symlink
      copy_configs
      migrate
    end
    
    restart
    
    # remove the maintenance screen
    #web.enable
  end
  
  desc "Long deploy will update the code migrate the database and restart the servers"
  task :master do
    # put up the maintenance screen
    #     ENV['REASON'] = 'an application upgrade'
    #     ENV['UNTIL']  = Time.now.+(600).strftime("%H:%M %Z")
    #     web.disable
    set :deploy_to, "/home/jill/master"
    set :branch, "master"
    set :env, "production"
    
    transaction do
      update_code
      symlink
      copy_configs
      migrate
    end
    
    restart

    # remove the maintenance screen
    #web.enable
  end
  
  desc "Rake database"
  task :migrate, :roles => :app, :only => {:primary => true} do
    run "cd #{deploy_to}/current && RAILS_ENV=#{env} rake db:schema:load"
  end
  
  desc "Restart the app server"
  task :restart, :roles => :app do
    run "cd #{deploy_to}/current && touch tmp/restart.txt"
  end
    
  desc "Tail the Rails log..."
  task :tail_logs, :roles => :app do
    run "tail -f #{deploy_to}/current/log/#{env}.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:server]} -> #{data}" 
      break if stream == :err    
    end
  end
end
