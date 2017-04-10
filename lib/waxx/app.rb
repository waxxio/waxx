# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::App
  extend self

  Version = [0,0,1]
  Root = `pwd`.chomp + "/app"
   
  class ParameterParseError < StandardError
  end

  attr :runs

  def init
    @runs = {}
    Waxx::Server.require_apps
  end

  def not_found(x, message:nil)
    if message.nil?
      @runs[:website][:page][:get].call(x, *(x.args))
    else
      x << message
    end
  end

  ##
  # Set an app runner
  def []=(name, opts)
    @runs[name.to_sym] = opts
  end

  ##
  # Get an app runner
  def [](name)
    @runs[name.to_sym]
  end

  def csrf_failure(x)
    error(x, status:400, type:"request", title:"Cross Site Request Forgery Error", message:"The request is missing the correct CSRF token.", args: [])
  end

  ##
  # Run an app
  #
  # Can run the request method (get post put patch delete) or the generic "run".
  #  1. x
  #  2. app: The name of the app (Symbol)
  #  3. act: The act to run (String or Symbol - type must match definition)
  #  4, meth: The request method (Symbol)
  #  5. args: The args to pass to the method (after x) (Array)
  def run(x, app, act, meth, args)
    if @runs[app.to_sym][act][meth.to_sym]
      begin
        @runs[app.to_sym][act][meth.to_sym][x, *args]
      rescue ArgumentError => e
        if Conf['debug']['on_screen']
          error(x, status: 405, type: "request", title: "Argument Error", message: "#{e.to_s}\n\n#{e.backtrace.join("\n")}")
        else
          debug e
          App.not_found(x)
        end
      end
    elsif @runs[app.to_sym][act][:run]
      begin
        @runs[app.to_sym][act][:run][x, *args]
      rescue ArgumentError => e
        if Conf['debug']['on_screen']
          error(x, status: 405, type: "request", title: "Argument Error", message: "#{e.to_s}\n\n#{e.backtrace.join("\n")}")
        else
          debug e
          App.not_found(x)
        end
      end
    else
      error(x, status: 405, type: "request", title: "Method Not Implemented", message: "The HTTP method requested is not implemented for this interface.")
    end
  end

  def error(x, status:200, type:"request", title:"An error occurred", message:"", args: [])
    x.res.status = status
    App[:app_error][type.to_sym][:get][x, title, message, *args]
  end

  def alert(x, status:200, type:"request", title:"Alert", message:"", args: [])
    x.res.status = status
    App[:app_error][type.to_sym][:get][x, title, message, *args]
  end

  def access?(x, acl:nil)
    return true if acl.nil?
    return true if %w(* all any public).include? acl.to_s
    return true if acl.to_s == "user" and x.usr?
    case acl
    when String, Symbol
      return (x.usr["grp"] and x.usr["grp"].include? acl.to_s)
    when Array
      return (x.usr["grp"] and (x.usr["grp"] & acl).size > 0)
    when Hash      
      g = nil
      if acl.keys.include? :any or acl.keys.include? :all
        g = acl[:any] || acl[:all]
      elsif acl.keys.include? :read and [:get, :head, :options].include? x.meth
        g = acl[:read]
      elsif acl.keys.include? :write and [:put, :post, :delete, :patch].include? x.meth
        g = acl[:write]
      else
        g = acl[x.meth]
      end
      return false if g.nil?
      return true if %w(* all any public).include? g.to_s
      return access?(x, g)
    when Proc
      return acl.call(x)
    else
      x.log.error "No acl type recognized in App.access? for acl: #{acl.inspect}"
      false
    end
    false
  end

  def log(x, cat, name, value=nil, id=nil)
    AppLog.log(x, cat:cat, name:name, value:value, id:id)
  end

  # Return a random string with no confusing chars (0Oo1iIl etc)
  def random_password(size=10)
    random_string(size, :chars, 'ABCDEFGHJKLMNPQRSTUVWXYabcdefghkmnpqrstuvwxyz23456789#%^&$*i-_+=')
  end

  def login_needed(x)
    if x.ext == "json"
    else
      App::Html.render(x,
        title: "Please Login",
        #message: {type:"info", message: "Please login"},
        content: App::Usr::Html.login(x, return_to: x.req.uri)
      )
    end
  end
end
