#!/usr/bin/env ruby
require 'mysql2'
require 'optparse'
require_relative 'settings'

class MysqlMonitor
  def initialize
    check_if_root
    @root_path = File.dirname(__FILE__)+'/'
    Dir.chdir @root_path
    load_config
    @con = db_connection
    handle_arguments
    complain
  end

  def check_if_root
    if ENV['USER'] != "root"
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
                       socket: Settings.mysql_socket,
                       username: Settings.mysql_user,
                       password: Settings.mysql_pass)
  end

  def handle_arguments
    o = OptionParser.new do |opts|
      opts.banner = 'Usage: rvmsudo mysql_monitor.rb [options]'
      opts.on_tail('-h', '--help', 'Show this message.') do
        puts opts
        exit
      end
      opts.on('-s', '--slave-running',
              'Shows if the slave is running') { handle_s_flag }
      opts.on('-d', '--seconds-behind',
              'Answers Seconds_Behind_Master. Exit-code in logarithmic scale.') { handle_d_flag }
    end
    begin o.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      puts o
      exit 1
    end
  end

  def handle_s_flag
    @con.query("SHOW SLAVE STATUS;", symbolize_keys: true).each do |row|
      io = row[:Slave_IO_Running]
      sql = row[:Slave_SQL_Running]
      puts "IO: #{io}, SQL: #{sql}"
      if io.eql?('No') || sql.eql?('No')
        @con.close
        exit 1
      end
    end
    @con.close
    exit
  end

  def handle_d_flag
    @con.query("SHOW SLAVE STATUS", symbolize_keys: true).each do |row|
      val = row[:Seconds_Behind_Master]
      @con.close
      val ? puts(val) : puts(-1)
      if val == 0
        res = 0
      elsif val == nil
        res = 256
      else
        res = Math::log10(val).round
      end
      res <= 255 ? exit(res) : exit(255)
    end
  end

  def complain
    puts 'You have to specify an argument!'
    puts 'To see available options run mysql_monitor.rb -h'
    exit 1
  end
end

MysqlMonitor.new
