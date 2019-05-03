#
# Version 03.05.2019
#

require 'colorize'

class RailsServiceTasks

  DEFAULT_ENV = 'production'
  DEFAULT_PORT = 9000

  RAILS_ROOT_DIR = File.expand_path(__dir__ + '/../..')
  CONFIG = YAML.load_file(File.expand_path(__dir__) + '/rails_service_tasks_config.yml')

  SYSTEMD_SERVICE_NAME = CONFIG['service_name']
  SYSTEMD_SERVICE_FILE_PATH = '/lib/systemd/system/' + SYSTEMD_SERVICE_NAME

  SYSTEMD_TEMPLATE_FILE_PATH = File.expand_path(__dir__) + '/rails_service_tasks_template.ini'

  def self.start
    ensure_run_as_root
    compile
    migrate
    if service_installed?
      start_as_service
    else
      start_manually
    end
    status
  end

  def self.stop
    puts "Stopping server ...".blue
    if service_installed?
      puts "- stopping server systemd service ... "
      `systemctl stop #{SYSTEMD_SERVICE_NAME}`
      puts "done".green
    elsif server_pids.any?
      server_pids.each do |pid|
        print " - Stopping server with PID " + pid.blue + " ... "
        `kill #{pid}`
        puts "done".green
      end
    else
      puts "No server running!".red
    end
    status
  end

  def self.restart
    stop
    start
  end

  def self.status
    puts "Check server status ...".blue
    if service_installed?
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
        puts "- " + "Server running as daemon (not service!) at PID #{pid}".green
      end
    else
      puts "- " + "Server not running".red
    end
  end

  def self.compile
    ensure_run_as_root
    print "- precompile assets ... "
    `rails assets:precompile`
    puts "done".green
    print "  -> ensure ownership #{CONFIG['run_as_user']}:#{CONFIG['run_as_root']} on assets ... "
     `chown #{CONFIG['run_as_user']}:#{CONFIG['run_as_root']} -R .`
    puts "done".green
  end

  def self.migrate
    ensure_run_as_root
    print "- check for migrations ... "
    `rails db:migrate`
    puts "done".green
  end

  def self.service_installed?
    ensure_systemd_available
    File.exist? SYSTEMD_SERVICE_FILE_PATH
  end

  def self.install_service
    ensure_run_as_root
    ensure_systemd_available
    puts "Installing server as systemd service ...".blue
    template = File.read SYSTEMD_TEMPLATE_FILE_PATH
    command = "rails s -e #{CONFIG['rails_env'] || DEFAULT_ENV} -p #{CONFIG['port'] || DEFAULT_PORT}"
    working_dir = RAILS_ROOT_DIR
    template.gsub!("{{DESCRIPTION}}",CONFIG['service_description'])
    template.gsub!("{{WORKING_DIR}}",working_dir)
    template.gsub!("{{COMMAND}}",command)
    template.gsub!("{{USER}}",CONFIG['run_as_user'])
    template.gsub!("{{GROUP}}",CONFIG['run_as_group'])
    print " - write service file to '#{SYSTEMD_SERVICE_FILE_PATH}' ... "
    f = File.open SYSTEMD_SERVICE_FILE_PATH, "w"
    f.write template
    f.close
    puts "done".green
    print " - enable service '#{SYSTEMD_SERVICE_NAME}' ... "
    `systemctl enable #{SYSTEMD_SERVICE_NAME}`
    puts "done".green
  end

  def self.uninstall_service
    ensure_run_as_root
    ensure_systemd_available
    puts "Uninstalling server as systemd service ...".blue
    print " - disable service '#{SYSTEMD_SERVICE_NAME}' ... "
    `systemctl disable #{SYSTEMD_SERVICE_NAME}`
    puts "done".green
    print " - delete service file '#{SYSTEMD_SERVICE_FILE_PATH}' ... "
    File.delete SYSTEMD_SERVICE_FILE_PATH
    puts "done".green
  end

  private

  def self.ensure_systemd_available
    unless systemd_available?
      raise "Systemd (systemctl) is not available on this machine"
    end
  end

  def self.systemd_available?
    cmd = `which systemctl`
    cmd != ""
  end

  def self.ensure_run_as_root
    unless ENV['USER'] == 'root'
      raise "This rake tasks must be run as sudo/root!".red
    end
    ENV['RAILS_ENV'] = CONFIG['rails_env']
  end

  def self.server_pids
    files = Dir[RAILS_ROOT_DIR + '/tmp/pids/*']
    pids = []
    if files.any?
      files.each do |f|
        pids += [File.read(f)]
      end
    end
    pids
  end

  def self.start_as_service
    print "- starting server at port #{CONFIG['port'].to_s.yellow} as systemd service ... "
    `systemctl start #{SYSTEMD_SERVICE_NAME}`
    puts "done".green
  end

  def self.start_manually
    print "- starting server at port #{CONFIG['port'].to_s.yellow} in daemon mode (will not be restarted on reboot!) ... "
    `rails s -e #{CONFIG['rails_env']} -p #{CONFIG['port']} -d`
    puts "done".green
  end
end