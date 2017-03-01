App::App.runs(
  default: "js",
  js: {
    desc: "Serve the application javascript files.",
    run: proc{|x,*args| 
      x.usr['no_cookies'] = true
      x.res['Content-Type'] = "application/javascript; charset=UTF-8"
      x << "app = {uid:#{x.usr['id']},cid:#{x.usr['cid']}};\n"
      # Read each file in the list and include it
      %w(usr/usr).each{|f|
        x << File.read("#{Conf['opts'][:base]}/app/#{f}.js") 
      }
      # JS for logged in users
      if x.usr?
        %w(issue/issue).each{|f|
          x << File.read("#{Conf['opts'][:base]}/app/#{f}.js") 
        }
      end
    }
  },
  ok: {
    desc: "Ping the app to see if it is ok",
    get: proc{|x, *args|
      x << (x.db.exec("select 1+1 as two").first['two'] == 2)
    }
  },
  sleep: {
    desc: "Sleep for seconds in args",
    acl: %w(user),
    run: proc{|x,*args| 
      sleep(args[0].to_i)
      x << "Done sleeping for #{args[0].to_i} seconds"
    }
  },
  error: {
    desc: "Raise an Error",
    acl: %w(user),
    run: proc{|x,*args| 
      raise "generic error"
    }
  },
  env: {
    desc: "Output all the input variables",
    #acl: "user",
    run: proc{|x, *args|  
      x.res["Content-Type"] = "text/plain"
      x << [
        "\n-------------------\nHeaders:\n",
        #x.req.env.inspect,
        x.req.env.map{|n,v| "#{n}: #{v}"}.join("\n"),
        "\n-------------------\nGet:\n",
        x.req.get.inspect,
        "\n-------------------\nPost:\n",
        x.req.post.inspect,
        "\n-------------------\nCookie:\n",
        x.req.cookies.inspect,
        "\n-------------------\nData:\n",
        x.req.data,
        "\n-------------------\nApp:\n",
        "meth: #{x.meth} / #{x.req.meth}\n",
        "uri: #{x.req.uri}\n",
        "app: #{x.app}\n",
        "act: #{x.act}\n",
        "oid: #{x.oid}\n",
        "args: #{x.args.inspect} / #{args.inspect}\n",
        "ext: #{x.ext}\n",
        "x['x']: #{x['x']}\n",
        "usr: #{x.usr['id']} / #{x.usr['dt']}\n",
        "\n",
        x.inspect,
        "\n"
      ].join
    }
  },
  raw: {
    desc: "Output all the input variables",
    #acl: "user",
    run: proc{|x, *args|  
      x.res["Content-Type"] = "text/plain"
      x << x.req.env.map{|n,v| "#{n}: #{v}"}.join("\r\n")
      x << "\r\n\r\n"
      x << x.req.data
    }
  },
  private: {
    desc: "A private page that requires login",
    acl: %w(user),
    run: proc{|x, *args|
      x << "Welcome"
    }
  },
  desc: {
    desc: "Describes all of the applications interfaces.",
    acl: "dev",
    get: proc{|x, app="all", *args|
      out = proc{|ap|
        re << "#{ap}\n"
        App[ap].each{|act,props|
          "  #{ac}:\n    #{App.runs[k][v][:desc]}\n    ACL: #{App.runs[k][v][:acl]}\n    Methods:\n"
          props.each{|m,pr|
            next if [:desc, :acl].include? m
            re << "      #{m}(#{pr.parameters.slice(1,99).join("/")}\n"
          }
        }
        re << "\n"
      }
      x.res.header['Content-Type'] = "text/plain"
      if app == "all"
        App.runs.keys.each{|k|
          out[k]
        }
      else
        out[app]
      end
    }
  },
  threads: {
    desc: "Show the status of all threads",
    get: proc{|x, *args|
      x.res.headers["Content-Type"] = "text/plain"
      Thread.list.each{|t|
        next if t[:name] == "main"
        x << "#{t[:name]}: #{t[:status]}\n"
      }
    }
  },
  stop: {
    desc: "kill all threads",
    acl: "admin",
    get: proc{|x, *args|
      x.res.headers["Content-Type"] = "text/plain"
      Thread.list.each{|t|
        next if t[:name] == "main"
        t[:db].close
        x << "#{t[:name]}: #{t[:status]}\n"
        t.exit
      }
    }
  }
)

