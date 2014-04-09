require 'mysql2'

class MysqlMonitor
  def initialize
    check_if_root
    @root_path = File.dirname(__FILE__)+'/'
    Dir.chdir @root_path
    load_config
    @con = db_connection
    handle_arguments
  end

  def check_if_root
    if ENV['USER'] != 'root'
      puts 'You need root privileges to run this script'
      exit 1
    end
  end

  def load_config
    if File.exist? @root_path+'config.yml'
      Settings.load!
    else
      Settings.create!
    end
  end

  def db_connection
    Mysql2::Client.new(host: 'localhost',
                       username: Settings.mysql_user,
                       password: Settings.mysql_pass)
  end
end

MysqlMonitor.new