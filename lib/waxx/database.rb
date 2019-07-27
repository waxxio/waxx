# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Database
  extend self

  def parse_uri(uri)
    _, schema, user, pass, host, port, database, opts = uri.split(/^(\w*):\/\/(\w*):?(.*)@([\w\-]*):?([0-9]*)?\/([\w\-]*)\??(.*)?$/)
   {
     type: schema,
     user: user,
     pass: pass,
     host: host,
     database: database,
     opts: Waxx::Http.query_string_to_hash(opts) 
   }
  end

  def connect(conf=Waxx['database'])
    # Parse the conf string to load the correct db engine
    engine = conf.split(":").first
    case engine.downcase
    when 'postgresql', 'pg'
      Waxx::Pg.connect(conf)
    when 'mysql2', 'mysql'
      # Parse the string 
      uri = parse_uri(conf)
      # Merge the opts into the params
      config = {
        username: uri/:user, 
        password: uri/:pass, 
        host: uri/:host, 
        port: uri/:port, 
        database: uri/:database
      } 
      config.merge!(uri/:opts)
      Waxx::Mysql2.connect(config)
    when 'sqlite3', 'sqlite'
      Waxx::Sqlite3.connect(conf.sub('sqlite3://',''))
    when 'mongodb', 'mongo'
      Waxx::Mongodb.connect(conf)
    else
      raise 'Unknown Database Type'
    end
  end
  
  # Define database connections in config.yaml or pass in a hash 
  #   {
  #     app: connection_string,
  #     blog: connection_string
  #   }
  def connections(dbs=Waxx['databases'])
    c = {}
    return c if dbs.nil?
    dbs.each{|name, conf|
      c[name.to_sym] = connect(conf)
      c.define_singleton_method(name){self[name.to_sym]}
    }
    c
  end

  def migrate(db_only=nil, opts={})
    dbs = connections
    dbs.each{|name, db|
      next if db_only and db_only.to_sym != name
      puts "Migrating: db.#{name}"
      # get the latest version
      latest = db.exec("SELECT value FROM waxx WHERE name = 'db.#{name}.migration.last'").first['value']
      Dir.entries("#{opts[:base]}/db/#{name}/").sort.each{|f|
        if f =~ /\.sql$/ and f > latest
          puts "  #{f}"
          db.exec(File.read("#{opts[:base]}/db/#{name}/#{f}"))
          db.exec("UPDATE waxx SET value = $1 WHERE name = 'db.#{name}.migration.last'",[f])
        end
      }
    }
    puts "Migration complete"
  end

  def [](name)
    app[name]
  end

  def collection(name)
    app[name]
  end

end
