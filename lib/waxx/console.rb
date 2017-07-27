# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

require 'stringio'

##
# The console module that is available with irb
# When `waxx console` is called, the dbs are connected and a StringIO class acts as the response container
module Waxx::Console
  extend self
  attr_accessor :db
  attr_accessor :x

  ##
  # Container for response output when using the console
  class Stringy < StringIO
    attr :out
    # Initialize with StringIO args
    def initialize(*args)
      super *args
      @out = ""
    end
    # Write to the output
    def print(str)
      @out << str
    end
    # Get the output
    def output
      @out
    end
    # Clear the out to run another request
    def reset
      @out = ""
    end
  end

  # Initialize the console variables
  def init
    @db = Waxx::Database.connections
    io = Stringy.new "GET /app/ok HTTP1/0\n#{ENV.map{|n,v| "#{n}: #{v}"}.join("\n")}"
    @x = Waxx::Server.process_request(io, @db)
  end

  # Run a GET request
  def get(path, opts={})
    puts path
    @db ||= Waxx::Database.connections
    io = Stringy.new "GET #{path} HTTP1/0\n#{ENV.map{|n,v| "#{n}: #{v}"}.join("\n")}"
    x = Waxx::Server.process_request(io, @db)
    #if ARGV[0] == "get"
      puts x.res.out
    #else
    #  x.res.out.join
    #end
  end

  # The x variable used on the console. Singleton.
  def x
    return @x if @x
    @x = Waxx::X.new
    @x.db = Waxx::Database.connections
    @x.usr = {un:ENV['USER']}
    @x.ua = {un:ENV['USER']}
    @x.req = Waxx::Req.new(ENV, nil, :get, "/", {}, {}, {}, Time.new)
    @x.res = Waxx::Res.new(Stringy.new,200,{},[],[],[])
    @x
  end

  ##
  # Handle console commands. These are called on the command line: waxx on, waxx deploy prod, waxx test app, etc.
  module Command
    extend self
    attr :x
    def on(opts)
      Waxx::Process::Runner.new('waxx').execute(daemonize: true, pid_path: opts[:pid_path], log_path: opts[:log_path]){
        ::App.start(opts)
      }
    end
    alias start on

    def off(opts)
      Waxx::Process::Runner.new('waxx').execute(kill: true, pid_path: opts[:pid_path])
    end
    alias stop off 

    def restart(opts)
      stop opts
      sleep 1
      start opts
    end
    alias buff restart

    def get(url=ARGV[1], opts={})
      Waxx['debug']['level'] = 0
      Waxx::Console.get(url, opts)
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
        require 'irb'
        puts "waxx console"
        #help = "Use the source, Luke"
        x = Waxx::Console.x
        binding.irb
        #IRB.setup(nil)
        #workspace = IRB::WorkSpace.new(self)
        #irb = IRB::Irb.new(workspace)
        #IRB.conf[:MAIN_CONTEXT] = irb.context
        #irb.eval_input
        #require 'lib/waxx/irb.rb'
        #@x = Waxx::Console.x
        #IRB.start_session(self) #"#{opts[:base]}/lib/waxx/irb_env.rb")
      else
        puts "Error: You need to call 'waxx console' from the root of a waxx installation."
        exit 1
      end
    end

    def config(opts)
      puts Waxx.data.send("to_#{opts[:format]}")
    end

    def deploy(target, opts)
      dep = YAML.load_file("#{opts[:base]}/opt/deploy.yaml")
      dep[target.to_s].each{|n,v|
        puts "Deploying #{target} to #{n}"
        `ssh #{v['user']}@#{v['host']} '#{v['command']}'`
      }
    end

    def init(opts)
      require_relative 'init'
      Waxx::Init.init(x, opts)
    end

    def migrate(db='app', opts={})
      Waxx::Database.migrate db, opts
    end

    def migration(db='app', name=nil, opts={})
      dt = Time.new.strftime('%Y%m%d%H%M')
      if name.nil?
        puts "Enter the name of the migration: "
        name = gets.chomp
      end           
      m_file = "db/#{db}/#{dt}-#{name.gsub(/\W/,"-")}.sql"
      File.open(m_file, "w"){|f|
        f.puts "BEGIN;\n\n\n\nCOMMIT;"
      }
      system "/usr/bin/env #{ENV['EDITOR']} #{m_file}"
    end

    def test(target, opts)
      require_relative 'test'
      start_time = Time.new
      re = {}
      total_tests = 0
      total_passed = 0
      if target == "waxx"
        tests = []
        Dir.entries(opts[:base] + '/test').each{|f|
          next if f =~ /^\./
          tests << f.sub(/\.rb$/,"")
          path = opts[:base] + '/test/' + f
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
      elsif target == "all" or target.nil?
        puts "app testing not impletemented yet: all"
      else
        puts "app testing not impletemented yet: #{target} #{opts[:format]}"
      end
      re["total_tests"] = total_tests
      re["total_passed"] = total_passed
      duration = ((Time.new - start_time) * 100000).to_i/100.0
      re["performance"] = "#{((total_passed.to_f / total_tests.to_f) * 100).to_i}% in #{duration} ms"
      puts re.send("to_#{opts[:format]}")
    end

  end

end
