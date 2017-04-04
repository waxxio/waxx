module App::Waxx
  extend ::Waxx::Object
  extend self

  runs(
    threads: {
      desc: "Show a list of threads",
      acl: 'dev',
      get: -> (x) {
				x.res.headers["Content-Type"] = "text/plain"
				Thread.list.each{|t|
					next if t[:name] == "main"
					x << "#{t[:name]}: #{t[:status]}\n"
				}
      }
    }
  )

end
