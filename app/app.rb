module App
  extend Waxx::App
  extend Waxx::Util
  extend Waxx::Session
  extend Waxx::Encrypt
  extend Waxx::Server
  extend self
  init
end

# Require layout engines
require_relative 'html'
