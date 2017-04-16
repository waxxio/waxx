# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::View

  attr :object
  attr :table
  attr :columns
  attr :joins
  attr :relations
  attr :matches
  attr :searches
  attr :order_by

  def init(tbl: nil, cols: nil, views: nil)
    @table = (tbl || App.table_from_class(name)).to_sym
    @object = App.get_const(App, @table)
    @relations = {}
    has(*cols) if cols
    as(views) if views
  end

  def [](c)
    @columns[c.to_sym]
  end


  ##
  # Columnas on a view can be defined in multiple ways:
  #
  #   has(
  #     :id,
  #     :name,  
  #     "company_name:company.name", # name:rel_name.col_name  "name" is the name of the col in the query, rel_name is the join table as defined in object, col_name is the column in the foreign table 
  #     [:creator, {table: "person", sql_select: "first_name || ' ' || last_name", label: "Creator"}]  # Array: [name, column (Hash)] 
  #     {modifier: {table: "person", sql_select: "first_name || ' ' || last_name", label: "Creator"}}
  #
  # 
  def has(*cols)
    init if @object.nil?
    #@joins = {}
    @columns = {}
    cols.each{|c|
      n = col = nil
      case c
      # Get the col from the object
      when Symbol
        n = c
        col = @object[c]
      # A related col (must be defined in the related object)
      when String
        n, col = string_to_col(c)
      # A custom col [name, col] col is a Hash
      when Array
        n, col = c
      # A custom col {name: col}, col is a Hash
      when Hash
        n, col = c.to_a[0]
      end
      if col.nil?
        debug "Column #{c} not defined in #{@object}."
        #raise "Column #{c} not defined in #{@object}."
      end
      #debug @relations.inspect
      #TODO: Deal with relations that have different names than the tables
      col[:views] << self rescue col[:views] = [self]
      @columns[n.to_sym] = col
    }
    @joins ||= Hash[@relations.map{|n, r| [n, %(#{r/:join} JOIN #{r/:foreign_table} AS #{n} ON #{r/:table}.#{r/:col} = #{n}.#{r/:foreign_col})] }]
  end

  ##
  # Column defined as a string in the format: name:foreign_table.foreign_col 
  # Converted to SQL: foreign_table.foreign_col AS name
  # Also adds entries in the @relations hash. @relations drive the SQL join statement
  # Joins are defined in the primary object of this view.
  def string_to_col(str)
    n, rel_name, col_name = parse_col(str)
    # Look in the primary and related objects for relations
    j = @object.joins/rel_name || @relations.values.map{|foreign_rel| 
      #debug "REL: #{foreign_rel}"
      o = App.get_const(App, foreign_rel/:foreign_table)
      #debug o
      #debug o.joins.inspect
      o.joins/rel_name
    }.compact.first
    #debug "j:#{j.inspect}, n: #{n}, rel: #{rel_name}, col: #{col_name}"
    begin
      col = (App.get_const(App, j/:foreign_table)/col_name).dup
      col[:table] = rel_name
    rescue NoMethodError => e
      debug "ERROR: NoMethodError: #{rel_name} does not define col: #{col_name}"
      raise e
    rescue NameError, TypeError => e
      debug "ERROR: Name or Type Error: #{rel_name} does not define col: #{col_name}"
      raise e
    end
    begin
      @relations[rel_name] ||= j #(App.get_const(App, j/:table)).joins
      #col[:table] = rel_name 
    rescue NoMethodError => e
      if col.nil?
        debug "col is nil"
      else
        debug "ERROR: App[#{col[:table]}] has no joins in View.has"
      end
      raise e
    end
    #debug n
    #debug col
    [n, col]
  end

  def parse_col(str)
    nam = rel = col = nil
    parts = str.split(/[:\.]/)
    case str
    # alias:relationship.column
    when /^\w+:\s*\w+\.\w+$/
      nam, rel, col = str.split(/[:\.]/).map{|part| part.strip}
    # relationship.column
    when /^\w+\.\w+$/
      rel, col = str.split(".")
    # alias:column (from primary object/table)
    when /^\w+:\w+$/
      nam, col = str.split(":")
    # column (from primary object/table)
    when /^\w+$/
      col = str
    else
      raise "Could not parse column definition in Waxx::View.parse_col (#{name}). Unknown match: #{str}."
    end             
    nam = col if nam.nil? 
    rel = @table if rel.nil?
    [nam, rel, col]
  end

  def joins_to_sql()
    #debug "JOINS: #{@joins.inspect}"
    return nil if @joins.nil? or @joins.empty?
    @joins.map{|n,v| v}.join(" ")
  end

  def as(*views)
    views.each{|v|
      eval("
        module #{name}::#{v.to_s.capitalize} 
          extend Waxx::#{v.to_s.capitalize}
          extend self
        end
      ")
    }
  end

  def match_in(*cols)
    @matches = cols.flatten
  end

  def search_in(*cols)
    @searches = cols.flatten
  end

  def default_order(ord)
    @order_by = ord
  end

  def run(x, id:nil, data:nil, where:nil, having:nil, order:nil, limit:nil, offset:nil, message:{}, as:x.ext, meth:x.meth, args:nil)
    case meth.to_sym
    when :get, :head
      if data.nil? or data.empty?
        if id
          data = get_by_id(x, id)
        else
          data = get(x, where:where, having:having, order:(order||x['order']), limit:(limit||x['limit']), offset:(offset||x['offset']), args:args)
        end
      end
    when :put, :post, :patch
      data = put_post(x, id, data, args:args)
    when :delete
      delete(x, id, args:args)
    else
      raise "Unknown request method in Waxx::View.run(#{name})"
    end
    layout = const_get(as.to_s.capitalize) rescue nil
    return App.not_found(x, message:"No layout defined for #{as}") if not layout
    if layout.respond_to? meth
      render(x, data, message: message, as: as, meth: meth) 
    else
      render(x, data, message: message, as: as, meth: "get") 
    end
  end
  alias view run

  def build_where(x, args: {}, matches: @matches, searches: @searches)
    return nil if matches.nil? and searches.nil?
    w_str = ""
    w_args = []
    q = args/:q || x['q']
    if q and searches
      w_str += "("
      searches.each_with_index{|c, i|
        w_str += " OR " if i > 0
        w_str += "LOWER(#{c}) like $1"
      }
      w_args << "%#{q.downcase}%"
      w_str += ")"
    end
    if matches
      matches.each_with_index{|c, i|
        next if (x/c).to_s == "" and (args/c).to_s == ""
        w_str += " AND " if w_str != ""
        col = self[c.to_sym]
        w_str += "#{c} #{col[:match] || "="} $#{w_args.size + 1}"
        w_args << (args/c || x/c)
      }
    end
    [w_str, w_args]
  end
                
  # Override this method in a view to change params
  def get(x, where:nil, having:nil, order:nil, limit:nil, offset:nil, args:nil, &blk)
    where ||= build_where(x, args: args)
    @object.get(x, 
      view: self, 
      where: where, 
      joins: joins_to_sql(),
      order: order, 
      limit: limit, 
      offset: offset
    )
  end

  def get_by_id(x, id)
    @object.get_by_id(x, id, view: self)
  end
  alias by_id get_by_id

  def put_post(x, id, data, args:nil)
    @object.put_post(x, id, data, view: self)
  end
  alias post put_post
  alias put put_post

  def delete(x, id)
    @object.delete(x, id)
  end

  def render(x, data, message: {}, as:x.ext, meth:x.meth)
    return App.not_found(x) unless const_defined?(as.to_s.capitalize)
    const_get(as.to_s.capitalize).send(meth, x, data, message: message)
  end

  def not_found(x, data:{}, message: {type: "NotFound", message:"The record you requested was not found."}, as:x.ext)
    self.const_get(as.to_s.capitalize).not_found(x, data:{}, message: message)
  end

  def debug(str, level=3)
    Waxx.debug(str, level)
  end
end
