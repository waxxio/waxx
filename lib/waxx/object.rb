# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Object

  attr :db
  attr :table
  attr :columns
  attr :pkey
  attr :joins
  attr :orders

  def init(db:"app", table:nil, pk:"id", cols:nil)
    @db = db.to_sym
    @table = (table || App.table_from_class(name)).to_sym
    @pkey = pk.to_sym
    @columns = {}
    @joins = {}
    @orders = {}
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
      if v[:is]
        r, tc = v[:is].split(":")
        t, c = tc.split(".")
        @joins[r] = {join: "INNER", table: t, col: c}
      end
      if v[:has]
        r, tc = v[:has].split(":")
        t, c = tc.split(".")
        @joins[r] = {join: "LEFT", table: t, col: c}
      end
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
    init if @table.nil?
    return App[@table] if opts.nil?
    App[@table] = opts
  end

  def run(x, act, meth, *args)
    App[@table][act.to_sym][meth.to_sym][x, *args]
  end

  def render(x, meth, *args)
    const_get(x.ext.capitalize).send(meth, x, *args)
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
    debug "object.get"
    select = parse_select(select, view)
    where = ["#{@table}.#{@pkey} = $1",id] if id and where.nil?
    # Block SQL injection in order clause. All order options must be defined in @orders.
    if order
      if not @orders/order
        debug("ERROR: Object.get order (#{order}) not found in @orders [#{@orders.keys.join(", ")}]. Sorting by #{@pkey} instead.")
        order = @pkey
      else
        order = @orders/order 
      end
    end
    if joins.nil? and view
      joins = view.joins_to_sql
    end
    q = {select:select, joins:joins, where:where, having:having, order:order, limit:limit, offset:offset}
    yield q if block_given?
    debug "object.get.select: #{q[:select]}"
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
    debug sql
    debug vals.join(", ")
    x.db[@db].exec(sql.join(" "), vals.flatten)
  end

  def get_by_id(x, id, select=nil, view:nil)
    get(x, id: id, select: select, view: view).first
  end
  alias by_id get_by_id

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
      if data/n
        names << n.to_s
        vars << "$#{i}"
        vals << cast(v, data/n)
        i += 1
      end
      ret << n.to_s
    }
    sql << names.join(",")
    sql << ") VALUES (#{vars.join(",")})"
    sql << " RETURNING #{returning || ret.join(",")}"
    debug(sql)
    debug(vals)
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
    ret = []
    i = 1
    debug "data: #{data}"
    cols.each{|n,v|
      debug "col: #{n}: #{v.inspect}"
      if data.has_key? n.to_s or data.has_key? n.to_sym
        set << "#{n} = $#{i}"
        vals << cast(v, data/n)
        ret << n.to_s
        i += 1
      end
    }
    sql << set.join(",")
    sql << " WHERE #{@pkey} = $#{i} #{where} RETURNING #{returning || ret.join(",")}"
    vals << id
    debug(sql)
    debug(vals)
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
    else
      val
    end
  end

  def delete(x, id)
    x.db[@db].exec("DELETE FROM #{@table} WHERE #{@pkey} = $1", [id])
  end

  def order(req_order, default_order='')
    return default_order if req_order.nil?
    return orders[req_order.to_sym] if orders.has_key? req_order.to_sym
    @pkey
  end
end
