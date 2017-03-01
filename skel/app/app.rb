require 'prawn'
require 'prawn/table'
require 'crypt/blowfish'

module App
  extend Waxx::App
  extend Waxx::Util
  extend Waxx::Session
  extend Waxx::Encrypt
  extend Waxx::Server
  extend self
  init

  def old_decrypt(str)
    blowfish = Crypt::Blowfish.new(Conf['encryption']['old_key'])
    blowfish.decrypt_string(Base64.decode64(str.to_s + "\n")).strip rescue ""
  end
end

# Require layout engines
require_relative 'html'
