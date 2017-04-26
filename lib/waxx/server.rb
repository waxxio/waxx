# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

##
# This is the core of waxx. 
#   Process:
#     start: A TCP server is setup listening on Waxx['server']['host'] on port Waxx['server']['port']
#     setup_threads: The thread pool is created with dedicated database connection(s)
#     loop: The requests are appended to the queue and the threads take one and:
#     process_request: The request is parsed (query, string, multipart, etc). The "x" vairable is defined
#     run_app: The proc/lambda is called with the x variable and any other optional variables
#     finish: The response is sent to the client, background jobs are processed, the thread takes the next request
module Waxx::Server
  extend self

  attr :last_load_time
  attr :queue

  def parse_uri(r)
    Waxx.debug "parse_uri"
    meth, uri, ver = r.split(" ")
    path, params = uri.split("?", 2)
    _, app, act, arg = path.split(".").first.split("/", 4)
    app = Waxx['default']['app'] if app.to_s == ''
    act = App[app.to_sym][:default] if act.to_s == '' and App[app.to_sym]
    act = Waxx['default']['act'] if act.to_s == ''
    oid = arg.split("/").first.gsub(/[^0-9]/,"").to_i rescue 0
    ext = path =~ /\./ ? path.split(".").last.downcase : Waxx['default']['ext']
    args = arg.split("/") rescue []
    get = Waxx::Http.query_string_to_hash(params).freeze
    Waxx.debug "parse_uri.oid #{oid}"
    [meth, uri, app, act, oid, args, ext, get]
  end

  def default_cookies
    {
      u: {uk: Waxx.random_string(20), la: Time.now.to_i},
      a: {la: Time.now.to_i}
    }
  end

  def csrf?(x)
    Waxx.debug "csrf?"
    if %w(PATCH POST PUT DELETE).include? x.req.meth
      if not Waxx::Csrf.ok?(x)
        true
      end
      puts "Cleared CSRF"
    end
    false
  end

  def default_response_headers(req, ext)
    {
      "Content-Type" => (Waxx::Http.content_types()[ext.to_sym] || "text/html; charset=utf-8"),
      "App-Server" => "waxx/1.0"
    }
  end
  
  def serve_file(io, uri)
    Waxx.debug "serve_file", 9
    return false if Waxx['file'].nil?
    file = "#{Waxx['file']['path']}#{uri.gsub("..","").split("?").first}"
    file = file + "/index.html" if File.directory?(file)
    return false unless File.exist? file
    ext = file.split(".").last
    io.print([
      "HTTP/1.1 200 OK",
      "Content-Type: #{(Waxx::Server.content_types/ext || 'octet-stream')}",
      "Content-Length: #{File.size(file)}",
      "",
      File.open(file,"rb") {|fh| fh.read}
    ].join("\r\n"))
    io.close
    ::Thread.current[:status] = "idle"
    true 
  end

  def process_request(io, db)
    begin
      Waxx.debug "process request", 4
      ::Thread.current[:status] = "working"
      start_time = Time.new
      r = io.gets
      #Waxx.debug r, 9
      meth, uri, app, act, oid, args, ext, get = parse_uri(r)
      #Waxx.debug([meth, uri, app, act, oid, args, ext, get].join(" "), 8)
      if meth == "GET" and Waxx['file'] and Waxx['file']['serve']
        #Waxx.debug "server_file"
        return if serve_file(io, uri)
      end
      #Waxx.debug "no-file"
      env, head = Waxx::Http.parse_head(io)
      #Waxx.debug head, 9
      cookie = Waxx::Http.parse_cookie(env['Cookie'])
      begin
        usr = cookie['u'] ? JSON.parse(::App.decrypt(cookie['u'][0])) : default_cookies[:u] 
      rescue => e
        Waxx.debug e.to_s, 1
        usr = default_cookies[:u]
      end
      begin
        ua = cookie['a'] ? JSON.parse(::App.decrypt(cookie['a'][0])) : {} 
      rescue => e
        Waxx.debug e.to_s, 1
        ua = {}
      end
      post, data = Waxx::Http.parse_data(env, meth, io, head)
      req = Waxx::Req.new(env, data, meth, uri, get, post, cookie, start_time).freeze
      res = Waxx::Res.new(io, 200, default_response_headers(req, ext), [], [], [])
      jobs = []
      x = Waxx::X.new(req, res, usr, ua, db, meth.downcase.to_sym, app, act, oid, args, ext, jobs).freeze
      if csrf?(x)
        Waxx::App.csrf_failure(x)
        finish(x, io)
        return
      end
      run_app(x)
      finish(x, io)
    rescue => e
      fatal_error(x, e)
      finish(x, io)
    end
  end

  def run_app(x)
    Waxx.debug "run_request"
    app = x.app.to_sym
    if App[app] 
      act = App[app][x.act.to_sym] ? x.act.to_sym : App[app][x.act] ? x.act : :not_found
      if App[app][act]
        if App.access?(x, acl:App[app][act][:acl])
          return App.run(x, app, act, x.meth.to_sym, x.args)
        else
          return App.login_needed(x)
        end
      end
    end
    App.not_found(x)
  end

  def set_cookies(x)
    return if x.usr/:no_cookies
    x.res.cookie( 
      name: Waxx['cookie']['user']['name'], 
      value: App.encrypt(x.usr.to_json), 
      secure: Waxx['cookie']['user']['secure']
    )
    x.res.cookie( 
      name: Waxx['cookie']['agent']['name'], 
      value: App.encrypt(x.ua.to_json), 
      expires: Time.now + (Waxx['cookie']['agent']['expires_years'].to_i * 31536000), 
      secure: Waxx['cookie']['agent']['secure']
    )
  end

  def finish(x, io)
    # Set last activity
    x.usr['la'] = Time.new.to_i
    set_cookies(x)
    Waxx.debug "Process time: #{(Time.new - x.req.start_time)*1000} ms."
    x.res.complete
    io.close
    x.jobs.each{|job| 
      job[0].call(*(job.slice(1, job.length)))
    }
    ::Thread.current[:status] = "idle"
    ::Thread.current[:last_used] = Time.new.to_i
    x # Return x for the console interfaces
  end

  def fatal_error(x, e)
    x.res.status = 503
    puts "FATAL ERROR: #{e}\n#{e.backtrace}"
    report = "APPLICATION ERROR\n=================\n\nUSR:\n\n#{x.usr.map{|n,v| "#{n}: #{v}"}.join("\n")}\n\nERROR:\n\n#{e}\n#{e.backtrace.join("\n")}\n\nENV:\n\n#{x.req.env.map{|n,v| "#{n}: #{v}"}.join("\n")}\n\nGET:\n\n#{x.req.get.map{|n,v| "#{n}: #{v}"}.join("\n")}\n\nPOST:\n\n#{x.req.post.map{|n,v| "#{n}: #{v}"}.join("\n")}\n\n"
    if Waxx['debug']['on_screen']
      x << "<pre>#{report.h}</pre>" 
    else
      App::Html.page(x, 
        title: "System Error", 
        content: "<h4><span class='glyphicon glyphicon-thumbs-down'></span> Sorry! Something went wrong on our end.</h4>
          <h4><span class='glyphicon glyphicon-thumbs-up'></span> The tech support team has been notified.</h4>
          <p>We will contact you if we need addition information. </p>
          <p>Sorry for the inconvenience.</p>"
      )
    end
    if Waxx['debug']['send_email'] and Waxx['debug']['email']
      begin
        to_email = Waxx['debug']['email']
        from_email = Waxx['site']['support_email']
        subject = "[Bug] #{Waxx['site']['name']} #{x.meth}:#{x.req.uri}"
        # Send email via DB
        App::Email.post(x, d:{
          to_email: to_email,
          from_email: from_email,
          subject: subject,
          body_text: report
        })
      rescue => e2
        begin
          # Send email directly
          Mail.deliver do
            from     from_email
            to       to_email
            subject  subject
            body     report
          end
        rescue => e3
           puts "FATAL ERROR: Could not send bug report email: #{e2}\n#{e2.backtrace} AND #{e3}\n#{e3.backtrace}"
        end
      end
    end
  end

  # Require first level apps in the Waxx::Root/app directory
  def require_apps
    Dir["#{Waxx["opts"][:base]}/app/*"].each{|f|
      next if f =~ /\/app\.rb$/ # Don't reinclude app.rb
      require f if f =~ /\.rb$/ # Load files in the app directory 
      if File.directory? f # Load top-level apps
        name = f.split("/").last
        require "#{f}/#{name}" if File.exist? "#{f}/#{name}.rb"
      end
    }
  end

  def reload
    reload_code
  end

  def reload_code
    require_apps
    $LOADED_FEATURES.each{|f| 
      if f =~ /^\// 
        if not f =~ /^\/usr\/local/
          if File.ctime(f) > @@last_load_time
            load(f)
          end
        end
      end
    }
    @@last_load_time = Time.new
  end

  def create_thread(id)
    Thread.new do
      Thread.current[:name]="waxx-#{Time.new.to_i}-#{id}"
      Thread.current[:status]="idle"
      Thread.current[:db] = Waxx['databases'].nil? ? {} : Waxx::Database.connections(Waxx['databases'])
      Thread.current[:last_used] = Time.new.to_i
      Waxx.debug "Create thread #{Thread.current[:name]}"
      loop do
        Waxx::Server.process_request(@@queue.pop, Thread.current[:db])
      end
    end
  end

  def setup_threads
    Waxx.debug "setup_threads"
    Thread.current[:name]="main"
    @@queue = Queue.new
    thread_count = Waxx['server']['min_threads'] || Waxx['server']['threads']
    1.upto(thread_count).each do |i|
      create_thread(i)
    end
    thread_count
  end

  def restart
    stop
    sleep(1)
    start
  end

  def start(options={})
    @@last_load_time = Time.new
    Waxx.debug "start #{$$}"
    thread_count = setup_threads
    server = TCPServer.new(Waxx['server']['host'], Waxx['server']['port'])
    puts "Listening on #{server.addr} with #{thread_count} threads (max_threads: #{Waxx['server']['max_threads'] || Waxx['server']['threads']})"
    while s = server.accept
      Waxx.debug "server.accept", 7
      reload_code if Waxx['debug']['auto_reload_code']
      @@queue << s
      Waxx.debug "q.size: #{@@queue.size}", 7
      Waxx.debug "q.waiting:  #{@@queue.num_waiting}", 7
      # Check threads
      Waxx::Supervisor.check
    end
    Waxx.debug "end start", 9
  end

  def stop(opts={})
    Waxx.debug "stop #{$$}"
    puts "Stopping #{Thread.list.size - 1} worker threads..."
    Thread.list.each{|t| 
      next if t[:name] == "main"
      puts "Killing #{t[:name]} with status #{t[:status]}"
      t[:db].close
      t.exit
    }
    puts "Done"
  end
end

