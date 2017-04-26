module Waxx::Route
  extend Waxx::Object
  extend self

  @app = :route

  runs(
    default: 'index',
    index: {
      desc: "Test a route with the @app variable",
      get: -> (x) { x << 'worked' }
    }
  )

end
