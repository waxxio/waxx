# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Encrypt
  extend self
  def encrypt(str, encode:'b64', cipher: Conf['encryption']['cipher'], key:Conf['encryption']['key'], iv:Conf['encryption']['iv'])
    aes = OpenSSL::Cipher.new(cipher)
    aes.encrypt
    aes.key = key
    aes.iv = iv if iv
    case encode.to_sym
      when :b64
        Base64.encode64(aes.update(str.to_s) + aes.final).chomp
      when :url
        http_escape(Base64.encode64(aes.update(str.to_s) + aes.final).chomp)
      when :bin
        aes.update(str.to_s) + aes.final
      else
        throw "Encoding not defined"
    end
  end
  def decrypt(str, encode:'b64', cipher: Conf['encryption']['cipher'], key:Conf['encryption']['key'], iv:Conf['encryption']['iv'])
    aes = OpenSSL::Cipher.new(cipher)
    aes.decrypt
    aes.key = key
    aes.iv = iv if iv
    case encode.to_sym
      when :b64
        aes.update(Base64.decode64(str.to_s + "\n")) + aes.final
      when :url
        aes.update(Base64.decode64(http_unescape(str.to_s) + "\n")) + aes.final
      when :bin
        aes.update(str.to_s) + aes.final
      else
        throw "Encoding not defined"
    end
  end
end
