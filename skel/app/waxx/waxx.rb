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
      acl: %w(user),
      run: -> (x, secs=1) {
        sleep(secs.to_i)
        x.res.as :txt
        x << "Done sleeping for #{secs.to_i} seconds"
      }
    },
    error: {
      desc: "Raise an Error",
      acl: %w(user),
      run: ->(x, *args){ 
        raise "generic error"
      }
    },
    env: {
      desc: "Output all the input variables",
      #acl: "user",
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
      #acl: "user",
      run: -> (x, *args) {  
        x.res.as :txt
        x << x.req.env.map{|n,v| "#{n}: #{v}"}.join("\r\n")
        x << "\r\n\r\n"
        x << x.req.data
      }
    },
    private: {
      desc: "A private page that requires login",
      acl: %w(user),
      run: ->(x){
        x.res.as :txt
        x << "Welcome"
      }
    },
    desc: {
      desc: "Describes all of the applications interfaces.",
      acl: "user",
      get: ->(x, app="all"){
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
        x.res.as :txt
        if x.ext == 'json'
          x << Oj.dump(re)
        else
          x << re.send("to_#{x.ext}")
        end
      }
    },
    threads: {
      desc: "Show the status of all threads",
      get: -> (x) {
        x.res.as :txt
        Thread.list.each{|t|
          next if t[:name] == "main"
          x << "#{t[:name]}: #{t[:status]}\n"
        }
      }
    },
    stop: {
      desc: "kill all threads",
      acl: "admin",
      get: -> (x) {
        x.res.as :txt
        Thread.list.each{|t|
          next if t[:name] == "main"
          t[:db].close
          x << "#{t[:name]}: #{t[:status]}\n"
          t.exit
        }
      }
    },
    golf: {
      desc: "Golf demo",
      get: -> (x) {
        x << %(<form action="/waxx/golf" method="get">
          Name: <input name="name"> <br>
          Handicap: <input name="handicap"> <br>
          <button type="submit">Submit</button>
          </form>
        )
        x << %(<form action="/waxx/golf" method="post">
          Name: <input name="name"> <br>
          Handicap: <input name="handicap"> <br>
          <button type="submit">Submit</button>
          </form>
        )
        x << "You got #{x['name']} with handicap #{x['handicap']}." if x['name']
      },
      post: -> (x) {
        x << "You posted #{x['name']} with handicap #{x['handicap']}."
      }
    },
    params: {
      desc: "Golf demo",
      get: -> (x) {
        x << %(<form action="/waxx/params?name=Joe&handicap[]=3" method="post">
          Name: <input name="name"> <br>
          Handicap: <input name="handicap[]"> <br>
          Handicap: <input name="handicap[]"> <br>
          <button type="submit">Submit</button>
          </form>
        )
        x << "You got #{x['name']} with handicap {get: #{x.req.get['handicap']}, post: #{x.req.post['handicap']}} ." if x['name']
      },
      post: -> (x) {
        x << "You posted #{x.req.get['name']} #{x.req.post['name']} #{x['name']} with handicap {get: #{x.req.get['handicap']}, post: #{x.req.post['handicap']}, x: #{x['handicap']} ." if x['name']
      }
    }
  )

end

require_relative 'route/waxx_route'
