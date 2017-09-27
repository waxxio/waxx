module App::AppError
  extend Waxx::Object
  extend self
  runs(
    request: {
      desc: "Display a request error (400)",
      get: lambda{|x, title, message=""|
        const_get(x.ext.capitalize).get(x, title, message)
      }
    }
  )
end
require_relative 'dhtml'
require_relative 'html'
require_relative 'json'
require_relative 'pdf'
