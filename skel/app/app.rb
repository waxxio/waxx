# Uncomment these to use them or add additional gems
# require 'pg'
# require 'mysql2'
# require 'sqlite3'
# require 'mail'

module App
  extend Waxx::App
  extend Waxx::Util
  extend Waxx::Encrypt
  extend Waxx::Server
  extend self
  init
  
  # App methods here that your apps share
end

# Require layout engines
require_relative 'html'
