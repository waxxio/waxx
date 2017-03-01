# Waxx Copyright (c) 2016-2017 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Libs
require 'socket'
require 'thread'
require 'openssl'
require 'base64'
require 'json'
require 'time'
require 'fileutils'
require 'yaml'

$:.unshift ENV['PWD']

module Conf
  extend self
  attr :data
  def load_yaml(base=ENV['PWD'], env="active")
    @data = ::YAML.load_file("#{base}/etc/#{env}/config.yaml")
  end
  def [](n)
    @data[n]
  end
  def []=(n, v)
    @data[n] = v
  end
end

def debug(str)
  Waxx.debug(str)
end

module Waxx
  extend self

  Version = "0.0.1"
  Root = `pwd`.chomp

  X = Struct.new(
    :req,
    :res,
    :usr,
    :ua,
    :db,
    :meth,
    :app,
    :act,
    :oid,
    :args,
    :ext,
    :jobs
  ) do
    def << str
      res << str.to_s
    end
    def [](k)
      req.post[k.to_s] || req.get[k.to_s]
    end
    def /(k)
      req.post[k.to_s] || req.get[k.to_s]
    end
    def usr?
      not (usr['id'].nil? or usr['id'].to_i == 0) 
    end
    def write?
      ['put', 'post', 'patch', 'delete'].include? meth
    end
    def group? g
      return false unless usr?
      usr['grp'].include? g.to_s
    end
    def groups?(*args)
      args.inject(0){|total, g| total + (group?(g) ? 1 : 0)} == args.size
    end
    def job(j, *args)
      jobs << [j, *args]
    end
  end

  Req = Struct.new(
    :env,
    :data,
    :meth,
    :uri,
    :get,
    :post,
    :cookies,
    :start_time
  )  

  Res = Struct.new(
    :server,
    :status,
    :headers,
    :out,
    :error,
    :cookies
  ) do

    def << str
      out << str
    end

    def [](n,v)
      headers[n]
    end

    def []=(n,v)
      headers[n] = v
    end
    
    def redirect(uri)
      self.status = 302
      headers['Location'] = uri
    end

    def head
      [
        "HTTP/1.1 #{status} #{Waxx::Http::Status[status.to_s]}",
        headers.map{|n,v| "#{n}: #{v}"},
        cookies.map{|c| 
          #debug("Set-Cookie: #{c}")
          "Set-Cookie: #{c}"
        },
        "\r\n"
      ].flatten.join("\r\n")
    end
    
    def complete
      re = out.join
      headers["Content-Length"] = re.bytesize
      server.print head
      server.print re
    end

    def cookie(name:"", value:nil, domain:nil, expires:nil, path:"/", secure:true, http_only: false, same_site: "Lax")
      expires = expires.nil? ? "" : "expires=#{Time === expires ? expires.rfc2822 : expires}; "
      cookies << "#{name}=#{Waxx::Http.escape(value.to_s)}; #{expires}#{";domain=#{domain}" if domain}; path=#{path}#{"; secure" if secure}#{"; HttpOnly" if http_only}; SameSite=#{same_site}"
    end
  end

  # A few helper functions

  def debug(str, level=3)
    puts str.to_s if level <= Conf['debug']['level'].to_i
  end

  def random_string(size=32, type=:an, chars=nil)
    if not type.to_sym == :chars
      types = {
        any: '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz~!@#$%^&*()_-+={[}]|:;<,>.?/',
        an: '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
        anl: '0123456789abcdefghijklmnopqrstuvwxyz'
      }
      chars = types[type.to_sym].split("")
    end
    opts = chars.size
    1.upto(size).map{chars[rand(opts)]}.join
  end

  def random_password(size=10)
    random_string(size, :chars, "ABCDEFGHJKLMNPQRSTUVWXYabcdefghkmnpqrstuvwxyz23456789")
  end

  def symbol_hash(data, keys=nil)
    h = {}
    if keys
      keys.each{|k| h[k.to_sym] = data[k.to_s] || data[k.to_sym]}
    else
      data.each{|k,v| h[k.to_sym] = v}
    end
    h
  end

end

# Require ruby files in waxx/ (except irb stuff)
require_relative 'waxx/app'
require_relative 'waxx/console'
require_relative 'waxx/csrf'
require_relative 'waxx/database'
require_relative 'waxx/encrypt'
require_relative 'waxx/error'
require_relative 'waxx/html'
require_relative 'waxx/http'
require_relative 'waxx/json'
require_relative 'waxx/object'
require_relative 'waxx/patch'
require_relative 'waxx/pdf'
require_relative 'waxx/process'
require_relative 'waxx/server'
require_relative 'waxx/session'
require_relative 'waxx/supervisor'
require_relative 'waxx/util'
require_relative 'waxx/view'
