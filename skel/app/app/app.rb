module App::App
  extend Waxx::Object
  extend self

  runs(
    default: "js",
    js: {
      desc: "Serve the application javascript files.",
      get: -> (x) { 
        x.usr['no_cookies'] = true
        x << "app = {uid:#{x.usr['id']},cid:#{x.usr['cid']}};\n"
        # Read each file in the list and include it
        %w(usr/usr.js).each{|f|
          x << File.read("#{Waxx/:opts/:base}/app/#{f}") 
        }
        # JS for logged in users
        if x.usr?
          %w().each{|f|
            x << File.read("#{Conf['opts'][:base]}/app/#{f}.js") 
          }
        end
      }
    },
    ok: {
      desc: "Ping the app to see if it is ok",
      get: -> (x) {
        if x.db.app.exec("select 1+1 as two").first['two'] == 2
          x << 'true'
        else
          x.res.status = 500
          x << false
        end
      }
    },
  )
end

require_relative 'log/app_log'
require_relative 'error/app_error'
