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

  ##
  # The Response Struct gets instanciated with each request (x.res)
  #
  # ```
  # x.res[name] = value    # Set a response header
  # x.res.as(extention)    # Set the Content-Type header based on extension
  # x.res.redirect '/path' # Redirect the client with 302 / Location header
  # x.res.location '/path' # Redirect the client with 302 / Location header
  # x.res.cookie(          # Set a cookie
  #   name: "", 
  #   value: nil, 
  #   domain: nil, 
  #   expires: nil, 
  #   path: "/", 
  #   secure: true, 
  #   http_only: false, 
  #   same_site: "Lax"
  # )
  # x << "ouput"           # Append output to the response body 
  # x.res << "output"      # Append output to the response body
  # ```
  Res = Struct.new(
    :server,
    :status,
    :headers,
    :out,
    :error,
    :cookies,
    :no_cookies
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
    
    def location(uri)
      self.status = 302
      headers['Location'] = uri
    end
    alias redirect location

    # Return the response headers
    def head
      [
        "HTTP/1.1 #{status} #{Waxx::Http::Status[status.to_s]}",
        headers.map{|n,v| "#{n}: #{v}"},
        (cookies.map{|c| 
          "Set-Cookie: #{c}"
        } unless no_cookies),
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

end

