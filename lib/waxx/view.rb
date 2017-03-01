# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::View

  attr :object
  attr :table
  attr :columns
  attr :joins
  attr :relations

  def init(tbl: nil, cols: nil, views: nil)
    @table = (tbl || App.table_from_class(name)).to_sym
    @object = App.get_const(App, @table)
    @relations = {}
    has(*cols) if cols
    as(views) if views
  end

  def has(*cols)
    init if @object.nil?
    #@joins = {}
    @columns = {}
    cols.each{|c|
      n = col = nil
      case c
      when Symbol
        n = c
        col = @object[c]
      when String
        n, rel_name, col_name = parse_col(c)
        # Look in the primary and related objects for relations
        j = @object.joins/rel_name || @relations.values.select{|rel| 
          #debug "REL: #{rel}"
          !rel[rel_name].nil?
        }.first/rel_name
        #debug "j:#{j.inspect}, n: #{n}, rel: #{rel_name}, col: #{col_name}"
        begin
          col = (App.get_const(App, j/:table)/col_name).dup
        rescue NoMethodError, NameError, TypeError => e
          debug "ERROR: #{rel_name} does not define col: #{col_name}"
          raise e
        end
        begin
          @relations[rel_name] ||= (App.get_const(App, j/:table)).joins
          col[:table] = rel_name 
        rescue NoMethodError => e
          if col.nil?
            debug "col is nil"
          else
            debug "ERROR: App[#{col[:table]}] has no joins in View.has"
          end
          raise e
        end
      when Array
        n = c[0]
        col = c[1]
      when Hash
        c.map{|nm,val|
          n = nm
          col = val
        }
      end
      if col.nil?
        debug "Column #{c} not defined in #{@object}."
        #raise "Column #{c} not defined in #{@object}."
      end
      #debug @relations.inspect
      #TODO: Deal with relations that have different names than the tables
      #col[:views] << self rescue col[:views] = [self]
      @columns[n.to_sym] = col
    }
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

  def run(x, id:nil, data:nil, where:nil, having:nil, order:nil, limit:nil, offset:nil, message:{}, as:x.ext, meth:x.meth, args:nil)
    case meth.to_sym
    when :get, :head
      if data.nil? or data.empty?
        if id
          data = get_by_id(x, id)
        else
          debug "view.get"
          data = get(x, where:where, having:having, order:(order||x['order']), limit:(limit||x['limit']), offset:(offset||x['offset']), args:args)
        end
      end
    when :put, :post
      data = put_post(x, id, data, args:args)
    when :delete
      delete(x, id, args:args)
    else
      raise "Unknown method in Waxx::View.run(#{name})"
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
                
  # Override this method in a view to change params
  def get(x, where:nil, having:nil, order:nil, limit:nil, offset:nil, args:nil, &blk)
    #debug("View.get_.joins: #{joins_to_sql}")
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
end
