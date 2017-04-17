# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

##
# A Waxx::View is like a database view. 
# You define the primary object and related tables and fields on the view and it handles some routine processes for you. 
# You can also just use it as a container for specialized business logic or complicated queries.
#
# Example usage:
#
# ```
# module App::Usr::List
#   extend Waxx::View
#   extend self
#
#   # Define what layouts to allow
#   as :json
#
#   # Define what fields are in the view
#   has(
#     # Fields that are in the 'usr' table
#     :id,
#     :usr_name,
#     :last_login_date,
#     :last_login_host,
#     :failed_login_count,
#     # Fields that are in the 'person' table. Relationships are defined in App::Usr.has(...)
#     "person_id: person.id",  # This column is accessible as 'person_id' on this view
#     "person.first_name",
#     "person.last_name",
#   )
# end
# ```
#
# This view definition will provide you with the following functionality:
#
# ```
# App::Usr::List.get(x)
# # Executes the following SQL:
# SELECT usr.id, usr.usr_name, usr.last_login_date, usr.last_login_host, usr.failed_login_count, 
#        person.id AS person_id, person.first_name, person.last_name
# FROM   usr LEFT JOIN person ON usr.id = person.id
# # And returns a PG::Result (If you are using the PG database connector)
# ```
module Waxx::View

  # The parent (primary) object. For example in App::Usr::List, App::Usr is the @object
  attr :object
  # The table name of the primary object
  attr :table
  # A hash of columns (See Waxx::Pg.has)
  attr :columns
  # A hash of name: join_sql. Normally set automatically when the columns are parsed.
  attr :joins
  # A hash of related tables. Normally set automatically when the columns are parsed.
  attr :relations
  # How to search the view by specific field
  attr :matches
  # How to search the view by the "q" parameter
  attr :searches
  # The default order of the results
  attr :order_by
  # A hash of how you can sort this view
  attr :orders

  ##
  # Initialize a view. This is normally done automatically when calling `has`.
  # 
  # Call init if the table, object, or layouts are non-standard. You can also set the attrs directly like `@table = 'usr'`
  #
  # ```
  # tbl: The name of the table
  # cols: Same as has
  # layouts: The layouts to auto-generate using waxx defaults: json, csv, tab, etc.
  # ```
  def init(tbl: nil, cols: nil, layouts: nil)
    @table = (tbl || App.table_from_class(name)).to_sym
    @object = App.get_const(App, @table)
    @relations = {}
    @orders = {}
    has(*cols) if cols
    as(layouts) if layouts
  end

  ##
  # Get a column on the view
  #
  # ```
  # App::Usr::Record[:usr_name] => {:type=>"character", :label=>"User Name", :table=>:usr, :column=>:usr_name, :views=>[App::Usr::Record, App::Usr::List, App::Usr::Signup]}
  # ```
  def [](c)
    @columns[c.to_sym]
  end

  ##
  # Columnas on a view can be defined in multiple ways:
  # 
  # ```
  # has(
  #   :id,                         # A field in the parent object
  #   :name,                       # Another field in the parent object
  #   "company_name:company.name", # name:rel_name.col_name  "name" is the name of the col in the query, rel_name is the join table as defined in object, col_name is the column in the foreign table 
  #   [:creator, {table: "person", sql_select: "first_name || ' ' || last_name", label: "Creator"}]  # Array: [name, column (Hash)] 
  #   {modifier: {table: "person", sql_select: "first_name || ' ' || last_name", label: "Creator"}}
  # ```
  # 
  def has(*cols)
    return @columns if cols.empty?
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
      @orders[n] = App.get_const(App, j/:foreign_table).orders/n
      @orders["_#{n}"] = App.get_const(App, j/:foreign_table).orders/"_#{n}"
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

  ##
  # Parse a column (internal method used by col)
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

  ## 
  # Turn the @joins attribute into SQL for the JOIN clause
  def joins_to_sql()
    return nil if @joins.nil? or @joins.empty?
    @joins.map{|n,v| v}.join(" ")
  end

  ##
  # Autogenerate the modules to do standard layouts like Json, Csv, or Tab
  #
  # ```
  # as :json
  # ```
  # 
  # This will generate the following code and allow the output of json formatted data for the view
  #
  # ```
  # module App::Usr::List::Json
  #   extend Waxx::Json
  #   extend self
  # end
  # ```
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

  ##
  # An array of columns to match in when passed in as params
  def match_in(*cols)
    @matches = cols.flatten
  end

  ##
  # Any array of columns to automatically search in using the "q" parameter
  def search_in(*cols)
    @searches = cols.flatten
  end

  ##
  # Set the default order. Order is a key of the field name. Use _name to sort descending.
  def default_order(ord)
    @order_by = ord
  end

  ##
  # Gets the data for the view and displays it. This is just a shortcut method.
  # 
  # This is normally called from the handler method defined in Object
  #
  # ```
  # App::Usr::List.run(x)
  # # Given a get request with the json extention, the above is a shortcut to:
  # data = App::Usr::List.get(x)
  # App::Usr::List::Json.get(x, data)
  # ```
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
  
  ##
  # Automatically build the where clause of SQL based on the parameters passed in and the definition of matches and searches.
  def build_where(x, args: {}, matches: @matches, searches: @searches)
    return nil if args.empty? or (matches.nil? and searches.nil?)
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

  ##              
  # Override this method in a view to change params
  def get(x, where:nil, having:nil, order:nil, limit:nil, offset:nil, args:{}, &blk)
    where  ||= build_where(x, args: args)
    order  ||= args/:order || @order_by
    limit  ||= args/:limit
    offset ||= args/:offset
    @object.get(x, 
      view: self, 
      where: where, 
      joins: joins_to_sql(),
      having: having,
      order: order, 
      limit: limit, 
      offset: offset
    )
  end

  ##
  # Get a single record of the view based on the primary key of the primary object
  def get_by_id(x, id)
    @object.get_by_id(x, id, view: self)
  end
  alias by_id get_by_id

  ## 
  # Save data
  def put_post(x, id, data, args:nil)
    @object.put_post(x, id, data, view: self)
  end
  alias post put_post
  alias put put_post

  ##
  # Delete a record by ID (primary key of the primary object)
  def delete(x, id)
    @object.delete(x, id)
  end

  ##
  # Render the view using the layout for meth and as
  #
  # `render(x, data, as: 'json', meth: 'get')`
  #
  # Uses logical defaults based on x.req
  def render(x, data, message: {}, as:x.ext, meth:x.meth)
    return App.not_found(x) unless const_defined?(as.to_s.capitalize)
    const_get(as.to_s.capitalize).send(meth, x, data, message: message)
  end

  ##
  # Send a not found message back to the client using the appropriate layout (json, csv, etc)
  def not_found(x, data:{}, message: {type: "NotFound", message:"The record you requested was not found."}, as:x.ext)
    self.const_get(as.to_s.capitalize).not_found(x, data:{}, message: message)
  end

  ##
  # A shorcut to Waxx.debug
  def debug(str, level=3)
    Waxx.debug(str, level)
  end
end
