require 'psych'
require 'io/console'

module Settings

  extend self

  @settings = {}

  def create!
    puts 'It appears that we lack a configuration file, lets create one now!'
    printf 'Enter MySQL user name: '
    mysql_user = gets.chomp
    printf 'Enter MySQL password: '
    mysql_pass = STDIN.noecho(&:gets).chomp; puts
    settings = {
        mysql_user: mysql_user,
        mysql_pass: mysql_pass
    }
    f = File.new(File.dirname(__FILE__)+'/config.yml', 'w')
    f.chown(-1,0)
    f.chmod(0600)
    f.write Psych.dump(settings)
    f.close
    load!
  end

  def load!
    @settings = Psych.load_file(File.dirname(__FILE__)+'/config.yml')
  end

  def method_missing(name, *args, &block)
    if @settings.has_key? name.to_sym
      @settings[name.to_sym]
    else
      @settings[name.to_sym] ||
          fail(NoMethodError, "unknown configuration root #{name}", caller)
    end
  end

end