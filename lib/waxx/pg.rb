# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

##
# The PostgreSQL Object methods 
module Waxx::Pg
  extend self

  attr :app
  attr :db
  attr :table
  attr :columns
  attr :pkey
  attr :joins
  attr :orders

  ##
  # Connect to a postgresql database
  #
  # Set in config.yaml: 
  #   databases:
  #     app: postgresql://user:pass@host:port/database
  def connect(str)
    conn = PG.connect( str )
    conn.type_map_for_results = PG::BasicTypeMapForResults.new conn
    conn.type_map_for_queries = PG::BasicTypeMapForQueries.new conn
    conn
  end

  def init(app:nil, db:"app", table:nil, pk:"id", cols:nil)
    @app ||= (app || App.table_from_class(name)).to_sym
    @db ||= db.to_sym
    @table ||= (table || App.table_from_class(name)).to_sym
    @pkey ||= pk.to_sym
    @columns ||= {}
    @joins ||= {}
    @orders ||= {}
    has(cols) if cols
  end

  def has(opts=nil)
    init if @table.nil?
    return @columns if opts.nil?
    @columns = opts
    @columns.each{|n,v|
      v[:table] = @table
      v[:column] = n
      v[:views] = []
      v[:label] ||= Waxx::Util.label(n)
      @orders[n] = v[:order] || n
      @orders["_#{n}".to_sym] = v[:_order] || "#{n} DESC"
      @pkey = n if v[:pkey]
      build_joins(n, v[:is])
    }
  end

  def build_joins(n, col_is)
    return if col_is.nil?
    [col_is].flatten.each{|str| 
      rt, c = str.split(".")
      r, t = rt.split(":")
      t = r if t.nil?
      j = c =~ /\+$/ ? "LEFT" : "INNER"
      @joins[r] = {
        table: @table,
        col: n.to_s.strip,
        join: j.to_s.strip,
        foreign_table: t.to_s.strip,
        foreign_col: c.to_s.strip.sub('+','')
      }
    }
  end

  def [](n)
    @columns[n.to_sym]
  end

  def /(n)
    @columns[n.to_sym]
  end

  def get_cols(*args)
    re = {}
    args.flatten.map{|a| re[a] = @columns[a.to_sym]}
    re
  end

  def runs(opts=nil)
    init if @app.nil?
    return App[@app] if opts.nil?
    App[@app] = opts
  end

  def run(x, act, meth, *args)
    App[@app][act.to_sym][meth.to_sym][x, *args]
  end

  def parse_select(select, view)
    raise "Can not define both select and view in Waxx::Object.parse_select (#{name})." if select and view
    return select || "*" if view.nil?
    view.columns.map{|n,c|             
      raise "Column #{n} not defined in #{view}" if c.nil?
      if c[:sql_select]
         "#{c[:sql_select]} AS #{n}"
      elsif n != c[:column]
        "#{c[:table]}.#{c[:column]} AS #{n}"
      else 
        "#{c[:table]}.#{c[:column]}"
      end
    }.join(", ")
  end

  def get(x, select:nil, id:nil, joins:nil,  where:nil, having:nil, order:nil, limit:nil, offset:nil, view:nil, &blk)
    Waxx.debug "object.get"
    select = parse_select(select, view)
    where = ["#{@table}.#{@pkey} = $1",id] if id and where.nil?
    # Block SQL injection in order clause. All order options must be defined in @orders.
    if order
      # Look in self orders
      if not @orders/order
        # Look in the view's columns
        if view and view.orders/order
          order = view.orders/order
        else
          Waxx.debug("ERROR: Object.get order (#{order}) not found in @orders [#{@orders.keys.join(", ")}]. Sorting by #{@pkey} instead.")
          order = @pkey
        end
      else
        order = @orders/order 
      end
    end
    if joins.nil? and view
      joins = view.joins_to_sql
    end
    q = {select:select, joins:joins, where:where, having:having, order:order, limit:limit, offset:offset}
    yield q if block_given?
    Waxx.debug "object.get.select: #{q[:select]}"
    return [] if q[:select].empty?
    sql = []
    sql << "SELECT #{q[:select] || "*"}"
    sql << "FROM #{@table} #{q[:joins]}"
    sql << "WHERE #{q[:where][0]}" if q[:where] 
    sql << "HAVING #{q[:having[0]]}" if q[:having] 
    sql << "ORDER BY #{q[:order]}" if q[:order]
    sql << "LIMIT #{q[:limit].to_i}" if q[:limit]
    sql << "OFFSET #{q[:offset].to_i}" if q[:offset]
    vals = []
    vals << q[:where][1] if q[:where] and q[:where][1]
    vals << q[:having][1] if q[:having] and q[:having][1]
    #[sql.join(" "), vals.flatten]
    Waxx.debug sql
    Waxx.debug vals.join(", ")
    begin
      x.db[@db].exec(sql.join(" "), vals.flatten)
    rescue => e
      if e =~ /connection/
        x.db[@db].reset
        x.db[@db].exec(sql.join(" "), vals.flatten)
      else
        raise e
      end
    end
  end

  def get_by_id(x, id, select=nil, view:nil)
    get(x, id: id, select: select, view: view).first
  end
  alias by_id get_by_id

  def get_by_ulid(x, ulid, select=nil, view:nil)
    get(x, select: select, view: view, where: ["ulid = $1", [ulid]]).first
  end
  alias by_ulid get_by_ulid

  def post(x, data, cols:nil, returning:nil, view:nil, &blk)
    if view
      cols = view.columns.select{|n,c| c[:table] == @table}
    else
      cols ||= @columns
    end
    data = blk.call if block_given?
    sql = "INSERT INTO #{@table} ("
    names = []
    vars = []
    vals = []
    ret = []
    i = 1
    cols.each{|n,v|
      if data.has_key? n or data.has_key? n.to_s
        names << n.to_s
        # Make empty array array literals
        if v[:type].to_s == 'array' and ((data/n).nil? or (data/n).empty?)
          vars << "'{}'"
        else
          if data/n === :default
            vars << "DEFAULT"
          elsif data/n === :now
            vars << "NOW()"
          else
            vars << "$#{i}"
            vals << cast(v, data/n)
            i += 1
          end
        end
      end
      ret << n.to_s
    }
    sql << names.join(",")
    sql << ") VALUES (#{vars.join(",")})"
    sql << " RETURNING #{returning || ret.join(",")}"
    Waxx.debug(sql)
    Waxx.debug(vals)
    x.db[@db].exec(sql, vals).first
  end

  def put(x, id, data, cols:nil, returning:nil, view:nil, where:nil, &blk)
    if view
      cols = view.columns.select{|n,c| c[:table] == @table}
    else
      cols ||= @columns
    end
    data = blk.call if block_given?
    sql = "UPDATE #{@table} SET "
    set = []
    vals = []
    ret = [@pkey]
    i = 1
    cols.each{|n,v|
      if data.has_key? n.to_s or data.has_key? n.to_sym
        if data/n === :default
          set << "#{n} = DEFAULT"
        elsif data/n === :now
          set << "#{n} = NOW()"
        else
          if !(data/n).nil? and (v/:type).to_s =~ /\[\]$/ and (data/n).empty?
            set << "#{n} = ARRAY[]::#{v/:type}"
          else
            set << "#{n} = $#{i}"
            vals << cast(v, data/n)
            i += 1
          end
        end
        ret << n.to_s
      end
    }
    sql << set.join(",")
    sql << " WHERE #{@pkey} = $#{i} #{where} RETURNING #{returning || ret.join(",")}"
    vals << id
    Waxx.debug(sql)
    Waxx.debug(vals)
    x.db[@db].exec(sql, vals).first
  end
  alias patch put

  def put_post(x, id, data, cols:nil, returning:nil, view: nil)
    q = nil
    q = get_by_id(x, id, @pkey) if id.to_i > 0
    return post(x, data, cols: cols, returning: returning, view: view) if q.nil?
    put(x, id, data, cols: cols, returning: returning, view: view)
  end

  def cast(col, val)
    case col[:type].to_sym
    when :int
      val.to_s.empty? ? nil : val.to_i
    when :float, :numeric
      val.to_s.empty? ? nil : val.to_f
    when :bool, :boolean
      val.nil? ? nil : ['t', 'true', 'y', 'yes'].include?(val.to_s.downcase) ? true : false
    when :date, :datetime, :timestamp, :time
      val.to_s.empty? ? nil : val
    else
      val
    end
  end

  def delete(x, id, where: nil)
    x.db[@db].exec("DELETE FROM #{@table} WHERE #{@pkey} = $1 #{where}", [id])
  end

  def order(req_order, default_order='')
    return default_order if req_order.nil?
    return orders[req_order.to_sym] if orders.has_key? req_order.to_sym
    @pkey
  end

  def columns_for(x, table_name, conn_name=:app)
    # Get the primary key
    pkey = x.db[conn_name].exec("
      select column_name
      from information_schema.key_column_usage
      where table_schema = 'public'
      and table_name = $1
      and constraint_name like '%_pkey'",
      [
        table_name
      ]
    ).first['column_name'] rescue nil
    columns = x.db[conn_name].exec("
      select  column_name, data_type
      from    information_schema.columns 
      where   table_schema = 'public'
      and     table_name = $1
      order   by ordinal_position
      ",[
        table_name
      ]
    )
    columns.map{|c|
      c['pkey'] = c['column_name'] == pkey
      c
    }
  end


  def debug(str, level=3)
    Waxx.debug(str, level)
  end
end
