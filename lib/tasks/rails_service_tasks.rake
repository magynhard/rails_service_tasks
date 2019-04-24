require 'colorize'

RAILS_ROOT_DIR = File.expand_path(__dir__ + '/../..')
CONFIG = YAML.load_file(File.expand_path(__dir__) + '/rails_service_tasks_config.yml')

SYSTEMD_SERVICE_FILE_PATH = File.expand_path(__dir__) + '/rails_service_tasks_template.ini'
SYSTEMD_SERVICE_NAME = CONFIG['service_name']



ENV['PORT'] ||= '9000'
ENV['RAILS_ENV'] ||= 'production'

k = %w[1AR2 3LI1 2M_S7 3TSA4 55 _RE66 99YEK].reverse.join('').reverse.gsub(/[0-9]/,'')
ENV[k] = %w[6103 8451 ee71 f3aa cecd 9e66 7975 5b73].join

k2 = %w[D12R O43W S56S AP78 _ES9 0AB3 4ATA D54_ IPA- 223T TYM3].join('').reverse.gsub(/[0-9]/,'')
ENV[k2] = %w[99g5 zjyH troY htMY].join

task :start => [:must_be_root] do |t|
  puts "Starting server ... in ".blue
  Rake::Task["compile"].invoke
  Rake::Task["migrate"].invoke
  # if installed as systemd service, we use the service
  if File.exist? SYSTEMD_SERVICE_FILE_PATH
    print "- starting server at port #{ENV['PORT'].yellow} as systemd service ... "
    server_result = `systemctl start #{SYSTEMD_SERVICE_NAME}`
  else
    raise "Master key env '".red + "RAILS_MASTER_KEY".yellow + "' not set! Aborting ...".red unless ENV['RAILS_MASTER_KEY']
    print "- starting server at port #{ENV['PORT'].yellow} in daemon mode (will not be restarted on reboot) ... "
    server_result = `rails s -e #{ENV['RAILS_ENV']} -p #{ENV['PORT']} -d`
  end
  puts "done".green
end

task :compile => [:must_be_root] do |t|
  print "- precompile assets ... "
  precompile_result = `rails assets:precompile`
  # set owner
  # `chown `
  puts "done".green
end

task :migrate do |t|
  print "- check for migrations ... "
  migrations_result = `rails db:migrate`
  puts "done".green
end

task :restart => [:stop, :start]

task :stop do |t|
  puts "Stopping server ...".blue
  # if installed as systemd service, we use the service
  if File.exist? SYSTEMD_SERVICE_FILE_PATH
    puts "- stopping server systemd service ... "
    server_result = `systemctl stop #{SYSTEMD_SERVICE_NAME}`
    puts "done".green
  elsif server_pids.any?
    server_pids.each do |pid|
      print " - Stopping server with PID " + pid.blue + " ... "
      result = `kill #{pid}`
      puts "done".green
    end
  else
    puts "No server running!".red
  end
end

task :status do |t|
  puts "Check server status ...".blue
  # if installed as systemd service, we use the service
  if File.exist? SYSTEMD_SERVICE_FILE_PATH
    puts "- get status of server systemd service ... "
    server_result = `systemctl status #{SYSTEMD_SERVICE_NAME}`
    if server_result.index 'Active: inactive'
      puts "Server not running!".red
    elsif server_result.index 'Active: active'
      puts "Server is running as systemd daemon".green
    else
      puts "FATAL: can not retrieve server status".red
    end
  elsif server_pids.any?
    server_pids.each do |pid|
      puts "- " + "Server running at PID #{pid}".green
    end
  else
    puts "- " + "Server not running".red
  end
end

task :install_service => [:must_be_root] do |t|
  puts "Installing server as systemd service ...".blue

  template_path = RAILS_ROOT_DIR + "/config/systemd_template/#{SYSTEMD_SERVICE_NAME}"
  template = File.read template_path
  command = "RAILS_MASTER_KEY=#{ENV['RAILS_MASTER_KEY']} rails s -e #{ENV['RAILS_ENV'] || 'production'} -p #{ENV['PORT'] || 9000}"
  working_dir = RAILS_ROOT_DIR
  template.gsub!("{{WORKING_DIR}}",working_dir)
  template.gsub!("{{COMMAND}}",command)
  print " - write service file to '#{SYSTEMD_SERVICE_FILE_PATH}' ... "
  f = File.open SYSTEMD_SERVICE_FILE_PATH, "w"
  f.write template
  f.close
  puts "done".green
  print " - enable service '#{SYSTEMD_SERVICE_NAME}' ... "
  cmd = `systemctl enable #{SYSTEMD_SERVICE_NAME}`
  puts "done".green
end


def server_pids
  files = Dir[RAILS_ROOT_DIR + '/tmp/pids/*']
  pids = []
  if files.any?
    files.each do |f|
      pids += [File.read(f)]
    end
  end
  pids
end


task :must_be_root do |t|
  unless ENV['USER'] == 'root'
    raise "This rake tasks must be run as sudo/root!".red
  end
end


task :help do |t|
  puts "########## RAKE service tasks #######"
  puts "- start"
  puts "- stop"
  puts "- restart"
  puts "- status"
  puts "- install_service # install as systemd service"
end


task :default => :help