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

  def connect(conf=Conf['database'])
    # Parse the conf string to load the correct db engine
    engine = conf.split(":").first
    case engine.downcase
    when 'postgresql'
      Waxx::Pg.connect(conf)
    when 'mysql2'
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
    when 'sqlite3'
      Waxx::Sqlite3.connect(conf.sub('sqlite3://',''))
    when 'mongodb'
      Waxx::Mongodb.connect(conf)
    else
      raise 'Unknown Dataabase Type'
    end
    #if Hash === conf
    #  conn = PG.connect( dbname: conf['name'], user: conf['user'], password: conf['password'], host: conf['host'] )
    #else
    #  conn = PG.connect( conf )
    #end
    #conn.type_map_for_results = PG::BasicTypeMapForResults.new conn
    #conn.type_map_for_queries = PG::BasicTypeMapForQueries.new conn
    #conn
  end
  
  # Define database connections in config.yaml or pass in a hash 
  #   {
  #     app: connection_string,
  #     blog: connection_string
  #   }
  def connections(dbs=Conf['databases'])
    c = {}
    dbs.each{|name, conf|
      c[name.to_sym] = connect(conf)
      c.define_singleton_method(name){self[name.to_sym]}
    }
    c
  end

  def migrate(opts)
    dbs = connections
    dbs.each{|name, db|
      puts "Migrating: db.#{name}"
      # get the latest version
      latest = db.exec("SELECT value FROM waxx WHERE name = 'migration.last'").first['value']
      Dir.entries("#{opts[:base]}/db/#{name}/").sort.each{|f|
        if f =~ /\.sql$/ and f > latest
          puts "  #{f}"
          db.exec(File.read("#{opts[:base]}/db/#{name}/#{f}"))
          db.exec("UPDATE waxx SET value = $1 WHERE name = 'migration.last'",[f])
        end
      }
    }
    puts "Migration complete"
  end

end
