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

module Waxx
  extend self

  Version = "0.0.1"
  Root = Dir.pwd

  ##
  # The X Struct gets instanciated with each request (x)
  #   x.req   # The request object (Instance of Waxx::Req)
  #   x.res   # The response object (Instance of Waxx::Res)
  #   x.usr   # The user session cookie 
  #     x.usr['id']            # Get the id value. 
  #     x.usr['name'] = value  # Set a user session value
  #   x.ua    # The User Agent / Client cookie
  #     x.ua['la']             # Get the last activity time of the user agent
  #     x.ua['name'] = value   # Set a user session value
  #   x.db    # The hash of database connections (0 or more)
  #     x.db.app.exec(sql, [arg1, arg2, argn])  # Run a query on the app database
  #   x.meth  # The request method as a symbol: :get, :post, :put, :patch, :delete
  #   # Path parameters example.com/app/act/[*args]
  #   x.app   # The (app or module) The first path parameter
  #   x.act   # The act (defined in Object.runs())
  #   x.oid   # The third arg as an int. Given example.com/person/record/42.json, then oid is 42
  #   x.args  # An array of arguments after /app/act/. Given POST example.com/customer/bill/10/dev/350.json, then args is ['10','dev','350']
  #   # When defining a the run proc, args are splatted into the function. So given the example request above and:
  #   module Customer
  #     extend Waxx::Postgres
  #     extend self
  #     runs(
  #       bill: {
  #         desc: "Bill a customer",
  #         acl: "internal",
  #         post: -> (x, customer_id, category, amount) {
  #           # The variables here are:
  #           # customer_id = '10'
  #           # category = 'dev'
  #           # amount = '350'
  #           # Note: All passed in args are strings
  #           #       but x.oid = 10 (as an int)
  #         }
  #       }
  #     )
  #   end
  #   x.ext   # The extension of the request: .json, .html, .pdf, etc. Default defined in Conf['default']['extension']
  #   # Background jobs (executed after the response is returned to the client. For example to deliver an email.)
  #   x.jobs  # An array of jobs
  #           # Jobs are added as procs with optional arguments (proc, *args).
  #   x.job(->(x, id){ App::Email.deliver(x, id) }, x, id) 
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

  ##
  # The Request Struct gets instanciated with each request (x.req)
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

  ##
  # The Response Struct gets instanciated with each request (x.res)
  #  x.res[name] = value    # Set a response header
  #  x.as(extention)        # Set the Content-Type header based on extension
  #  x.res.redirect '/path' # Redirect the client with 302 / Location header
  #  x.res.cookie(          # Set a cookie
  #    name:"", 
  #    value:nil, 
  #    domain:nil, 
  #    expires:nil, 
  #    path:"/", 
  #    secure:true, 
  #    http_only: false, 
  #    same_site: "Lax"
  #  )
  #  x << "ouput"           # Append output to the response body 
  #  x.res << "output"      # Append output to the response body
  Res = Struct.new(
    :server,
    :status,
    :headers,
    :out,
    :error,
    :cookies
  ) do

    # Send output to the client (may be buffered)
    def << str
      out << str
    end

    def [](n,v)
      headers[n]
    end

    def []=(n,v)
      headers[n] = v
    end

    def as(ext)
      headers['Content-Type'] = Waxx::Http.ctype(ext)
    end
    
    def redirect(uri)
      self.status = 302
      headers['Location'] = uri
    end

    # Return the response headers
    def head
      [
        "HTTP/1.1 #{status} #{Waxx::Http::Status[status.to_s]}",
        headers.map{|n,v| "#{n}: #{v}"},
        cookies.map{|c| 
          "Set-Cookie: #{c}"
        },
        "\r\n"
      ].flatten.join("\r\n")
    end
    
    # Output the headers and the body
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

  ##
  # Output to the log
  #   Waxx.debug(
  #     str,          # The text to output
  #     level         # The number 0 (most important) - 9 (least important)
  #   )
  #   # Set the level in config.yaml (debug.level) of what level or lower to ouutput
  def debug(str, level=3)
    puts str.to_s if level <= Conf['debug']['level'].to_i
  end

  ##
  # Get a pseudo-random (non-cryptographically secure) string to use as a temporary password.
  # If you need real random use SecureRandom.random_bytes(size) or SecureRandom.base64(size).
  #  1. size: Length of string
  #  2. type: [
  #       any: US keyboard characters
  #       an:  Alphanumeric (0-9a-zA-Z)
  #       anl: Alphanumeric lower: (0-9a-z)
  #       chars: Your own character list
  #     ]
  #  3. chars: A string of your own characters
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

end

