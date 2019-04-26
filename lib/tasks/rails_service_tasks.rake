#
# Version 27.04.2019
#

require_relative 'rails_service_tasks'


task :start do |t|
  RailsServiceTasks.start
end

task :compile do |t|
  RailsServiceTasks.compile
end

task :migrate do |t|
  RailsServiceTasks.migrate
end

task :restart do |t|
  RailsServiceTasks.restart
end

task :stop do |t|
  RailsServiceTasks.stop
end

task :status do |t|
  RailsServiceTasks.status
end

task :install_service do |t|
  RailsServiceTasks.install_service
end

task :uninstall_service do |t|
  RailsServiceTasks.uninstall_service
end

task :help do |t|
  puts "########## RAKE service tasks #######"
  puts "- start              # start server"
  puts "- stop               # stop server"
  puts "- restart            # run stop and start"
  puts "- status             # check if server is running"
  puts "- install_service    # install as systemd service"
  puts "- uninstall_service  # install as systemd service"
end


task :default => :help