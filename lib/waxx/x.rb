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
  # The X Struct gets instanciated with each request (x)
  # ```
  # x.req   # The request object (Instance of Waxx::Req)
  # x.res   # The response object (Instance of Waxx::Res)
  # x.usr   # The user session cookie 
  #   x.usr['id']            # Get the id value. 
  #   x.usr['name'] = value  # Set a user session value
  # x.ua    # The User Agent / Client cookie
  #   x.ua['la']             # Get the last activity time of the user agent
  #   x.ua['name'] = value   # Set a user session value
  # x.db    # The hash of database connections (0 or more)
  #   x.db.app.exec(sql, [arg1, arg2, argn])  # Run a query on the app database
  # x.meth  # The request method as a symbol: :get, :post, :put, :patch, :delete
  # # Path parameters example.com/app/act/[*args]
  # x.app   # The (app or module) The first path parameter
  # x.act   # The act (defined in Object.runs())
  # x.oid   # The third arg as an int. Given example.com/person/record/42.json, then oid is 42
  # x.args  # An array of arguments after /app/act/. Given POST example.com/customer/bill/10/dev/350.json, then args is ['10','dev','350']
  # # When defining a the run proc, args are splatted into the function. So given the example request above and:
  # module Customer
  #   extend Waxx::Postgres
  #   extend self
  #   runs(
  #     bill: {
  #       desc: "Bill a customer",
  #       acl: "internal",
  #       post: -> (x, customer_id, category, amount) {
  #         # The variables here are:
  #         # customer_id = '10'
  #         # category = 'dev'
  #         # amount = '350'
  #         # Note: All passed in args are strings
  #         #       but x.oid = 10 (as an int)
  #       }
  #     }
  #   )
  # end
  # x.ext   # The extension of the request: .json, .html, .pdf, etc. Default defined in Waxx['default']['extension']
  # # Background jobs (executed after the response is returned to the client. For example to deliver an email.)
  # x.jobs  # An array of jobs
  #         # Jobs are added as procs with optional arguments (proc, *args).
  # x.job(->(x, id){ App::Email.deliver(x, id) }, x, id) 
  # ```
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
      begin
        req.post[k.to_s] || req.get[k.to_s]
      rescue
        nil
      end
    end
    def /(k)
      begin
        req.post[k.to_s] || req.get[k.to_s]
      rescue
        nil
      end
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

end

