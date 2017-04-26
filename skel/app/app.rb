require 'pg'
# Uncomment these to use them
# require 'mysql2'
# require 'sqlite3'
require 'mail'

module App
  extend Waxx::App
  extend Waxx::Util
  extend Waxx::Encrypt
  extend Waxx::Server
  extend self
  init
  
  # App methods here that you apps share
end

# Require layout engines
require_relative 'html'
