# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Database
  extend self

  def connection(conf=Conf['database'])
    if Hash === conf
      conn = PG.connect( dbname: conf['name'], user: conf['user'], password: conf['password'], host: conf['host'] )
    else
      conn = PG.connect( conf )
    end
    conn.type_map_for_results = PG::BasicTypeMapForResults.new conn
    conn.type_map_for_queries = PG::BasicTypeMapForQueries.new conn
    conn
  end
  
  def connections(dbs=Conf['databases'])
    c = {}
    dbs.each{|name, conf|
      c[name.to_sym] = connection(conf)
      c.define_singleton_method(name){self[name.to_sym]}
    }
    c
  end

  def migrate(opts)
    db = connection
    # get the latest version
    latest = db.exec("SELECT value FROM waxx WHERE name = 'migration.last'").first['value']
    Dir.entries("#{opts[:base]}/db/migrations/").sort.each{|f|
      if f =~ /\.sql$/ and f > latest
        puts "Migrating #{f}"
        db.exec(File.read("#{opts[:base]}/db/migrations/#{f}"))
        db.exec("UPDATE waxx SET value = $1 WHERE name = 'migration.last'",[f])
      end
    }
    puts "Migration complete"
  end

end
