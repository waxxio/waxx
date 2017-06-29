module App::Home
  extend Waxx::Object
  extend self

  runs(
    default: 'welcome',
    welcome: {
      desc: "Welcome to Waxx default page",
      get: -> (x) {
        Html.welcome(x)
      }
    }
  )
end

require_relative 'html'
