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
        App.start(opts)
      }
    end
    alias on start

    def stop(opts)
      #App.stop(opts)
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
  end
end
