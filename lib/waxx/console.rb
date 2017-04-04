# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

require 'stringio'

module Waxx::Console
  extend self
  attr_accessor :db
  attr_accessor :x

  class Stringy < StringIO
    attr 'out'

    def initialize(*args)
      super *args
      @out = ""
    end
    def print(str)
      @out << str
    end
    def output
      @out
    end
  end

  def init
    @db = Waxx::Database.connection
    io = Stringy.new "GET /app/ok HTTP1/0\n#{ENV.map{|n,v| "#{n}: #{v}"}.join("\n")}"
    @x = Waxx::Server.process_request(io, @db)
  end

  def get(path, opts={})
    io = Stringy.new "GET #{path} HTTP1/0\n#{ENV.map{|n,v| "#{n}: #{v}"}.join("\n")}"
    x = Waxx::Server.process_request(io, Waxx::Database.connection)
    if ARGV[0] == "get"
      puts x.res.out
    else
      x.res.out.join
    end
  end

  def x
    return @x if @x
    @x = Waxx::X.new
    @x.db = Waxx::Database.connections
    @x.usr = {un:ENV['USER']}
    @x.ua = {un:ENV['USER']}
    @x.req = Waxx::Req.new(ENV, nil, :get, "/", {}, {}, {}, Time.new)
    @x.res = Waxx::X.new(Stringy.new,200,{},[],[],[])
    @x
  end

  module Command
    extend self
    attr :x
    def start(opts)
      Waxx::Process::Runner.new('waxx').execute(daemonize: true, pid_path: opts[:pid_path], log_path: opts[:log_path]){
        ::App.start(opts)
      }
    end
    alias on start

    def stop(opts)
      Waxx::Process::Runner.new('waxx').execute(kill: true, pid_path: opts[:pid_path])
    end
    alias off stop

    def restart(opts)
      stop opts
      sleep 1
      start opts
    end
    alias buff restart

    def get(opts)
      App.get(ARGV[1], opts)
    end

    def post(opts)
      App.post(ARGV[1], opts)
    end

    def put(opts)
      App.put(ARGV[1], opts)
    end

    def delete(opts)
      App.delete(ARGV[1], opts)
    end

    def console(opts)
      if File.exist? 'app/app.rb'
        #system("WAXX_CONSOLE=1 irb -r ./lib/waxx")
        #exit 0
    #    require 'irb'
        require 'lib/waxx/irb.rb'
      # puts "Run the following: "
      # puts "  extend Waxx::Console"
      # puts "  x = get_x"
      # puts ""
      # puts "'x' must be passed to all data methods: App::Person::Record.get(x, id: 1)"
      # puts "Get URL: get /app/env"
        #ARGV.shift
        @x = Waxx::Console.x
        IRB.start_session(self) #"#{opts[:base]}/lib/waxx/irb_env.rb")
      else
        puts "Error: You need to call 'waxx console' from the root of a waxx installation."
        exit 1
      end
    end

    def conf(opts)
      puts "opts:\n#{opts.inspect}\n\nconf:\n#{Conf.data.inspect}"
    end

    def deploy(opts)
      dep = YAML.load_file("#{opts[:base]}/etc/deploy.yaml")
      dep[opts[:to]].each{|n,v|
        puts "Deploying #{opts[:to]} to #{n}"
        `ssh #{v['user']}@#{v['host']} '#{v['command']}'`
      }
    end

    def init(opts)
      require 'lib/waxx/init'
      Waxx::Init.init(x, opts)
    end

    def migrate(opts)
      Waxx::Database.migrate opts
    end

    def migration(opts)
      dt = Time.new.strftime('%Y%m%d%H%M')
      if opts[:name].nil?
        puts "Enter the name of the migration: "
        opts[:name] = gets.chomp
      end           
      m_file = "db/migrations/#{dt}-#{opts[:name].gsub(/\W/,"-")}.sql"
      File.open(m_file, "w"){|f|
        f.puts "BEGIN;\n\n\n\nCOMMIT;"
      }
      system "/usr/bin/env #{ENV['EDITOR']} #{m_file}"
    end

    def test(opts)
      require 'lib/waxx/test.rb'
      start_time = Time.new
      re = {}
      total_tests = 0
      total_passed = 0
      if opts[:app] == "waxx"
        tests = []
        Dir.entries(opts[:base] + '/lib/waxx/tests').each{|f|
          next if f =~ /^\./
          tests << f.sub(/\.rb$/,"")
          path = opts[:base] + '/lib/waxx/tests/' + f
          puts path
          require path
        }

        tests.each{|waxx_module_test|
          re[waxx_module_test] = Waxx.send(waxx_module_test)
          re[waxx_module_test].each{|file, mod| 
            mod.map{|meth, test| 
              total_tests += test['tests']
              total_passed += test['tests_passed']
            }
          }
        }
      elsif opts[:app] == "all"
        puts "app testing not impletemented yet: all"
      else
        puts "app testing not impletemented yet: #{opts[:app]} #{opts[:format]}"
      end
      re["total_tests"] = total_tests
      re["total_passed"] = total_passed
      duration = ((Time.new - start_time) * 100000).to_i/100.0
      re["performance"] = "#{((total_passed.to_f / total_tests).to_i) * 100}% in #{duration} ms"
      puts re.send("to_#{opts[:format]}")
    end

  end

end
