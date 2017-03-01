module App::App
  extend Waxx::Object
  init
end
require_relative 'run'
require_relative 'log/app_log'
require_relative 'error/app_error'
