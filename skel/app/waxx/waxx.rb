module App::Waxx
  extend Waxx::Object
  extend self

  runs(
    ok: {
      desc: "Ping the app database to see if it is ok",
      get: -> (x) {
        x << (x.db.app.exec("select 1+1 as two").first['two'] == 2)
      }
    },
    sleep: {
      desc: "Sleep for seconds in args",
      acl: %w(dev),
      run: -> (x, secs=1) {
        sleep(secs.to_i)
        x.res.as :txt
        x << "Done sleeping for #{secs.to_i} seconds"
      }
    },
    error: {
      desc: "Raise an Error (to see what the error looks like and send email if configured)",
      acl: %w(dev),
      run: ->(x, *args){ 
        raise "test error"
      }
    },
    env: {
      desc: "Output all the input variables",
      acl: "dev",
      run: ->(x, *args) {  
        x.res.as :txt
        x << {"x" => {
          "meth" => x.meth,
          "app" => x.app,
          "act" => x.act,
          "oid" => x.oid,
          "args" => x.args,
          "ext" => x.ext,
          "usr" => x.usr,
          "ua" => x.ua,
          "req" => {
            "meth" => x.req.meth,
            "get" => x.req.get,
            "post" => x.req.post,
            "env" => x.req.env,
            "cookies" => x.req.cookies,
            "data" => x.req.data,
          }
        }}.to_yaml
      }
    },
    raw: {
      desc: "Output all the input variables",
      run: -> (x, *args) {  
        x.res.as :txt
        x << x.req.env.map{|n,v| "#{n}: #{v}"}.join("\r\n")
        x << "\r\n\r\n"
        x << x.req.data
      }
    },
    desc: {
      desc: "Describes all of the applications interfaces.",
      acl: "dev",
      get: -> (x, app="all"){
        return App.error(x, status: 300, title: 'Request Error', message: 'This method only return json or yaml') unless %w(json yaml).include? x.ext
        re = {}
        describe = -> (ap) {
          re[ap.to_s] = {}
          return nil if App[ap].nil?
          App[ap].each{|act,props|
            re[ap.to_s][act.to_s] = {}
            if props.respond_to?('each')
              props.each{|n, v|
                if Proc === v
                  re[ap.to_s][act.to_s][n.to_s] = Hash[v.parameters.map{|param| [param[1].to_s, param[0].to_s]}]
                else
                  re[ap.to_s][act.to_s][n.to_s] = v
                end
              }
            else
              re[ap.to_s][act.to_s] = props
            end
          }
        }
        if app == "all"
          App.runs.keys.each{|k|
            describe[k]
          }
        else
          describe[app]
        end
        x << re.send("to_#{x.ext}")
      }
    },
    threads: {
      desc: "Show the status of all threads",
      acl: "dev",
      get: -> (x) {
        x.res.as :txt
        Thread.list.each{|t|
          next if t[:name] == "main"
          x << "#{t[:name]}: #{t[:status]}\n"
        }
      }
    },
  )

end
