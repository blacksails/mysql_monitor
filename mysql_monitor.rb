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

  def handle_arguments
    o = OptionParser.new do |opts|
      opts.banner = 'Usage: mysql_monitor.rb [options]'
      opts.on_tail('-h', '--help', 'Show this message.') do
        puts opts
        exit
      end
      opts.on('-s', '--slave-running',
              'Answers YES and noError(0) if slave is running else NO and error(1)') { handle_s_flag }
      opts.on('-d', '--slave-running',
              'Answers Seconds_Behind_Master') { handle_d_flag }
    end
    begin o.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      puts o
      exit 1
    end
  end

  def handle_s_flag
    @con.query("SHOW GLOBAL STATUS LIKE 'slave_running'", symbolize_keys: true).each do |row|
      val = row[:Value]
      puts val
      @con.close
      if val.eql? 'OFF'
        exit 1
      end
      exit
    end
  end

  def handle_d_flag
    @con.query("SHOW SLAVE STATUS", symbolize_keys: true).each do |row|
      val = row[:Seconds_Behind_Master]
      puts val
      @con.close
      exit
    end
  end

  def complain
    puts 'You have to specify an argument!'
    puts 'To see available options run mysql_monitor.rb -h'
    exit 1
  end
end

MysqlMonitor.new
