# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Object

  attr :app

  ##
  # Define the app interface (routes), methods to run, and access control
  #
  # ```
  # module App::Person
  #   extend Waxx::Object
  #
  #   runs(
  #     default: 'list', 
  #     list: {
  #       desc: "List people",
  #       acl: "user",
  #       get: -> (x) {
  #         x << x.db.app.exec("SELECT * FROM person ORDER BY last_name, first_name").map{|r| r}.to_json
  #       }
  #     }
  #   )
  # end
  # ```
  #
  # The special "default" key can be used to run a method when the act is not defined. In the example above, a request to `/person` will act like a request to `/person/list`
  #
  # Attributes of each argument to the runs method
  #
  # ```
  # desc:   A text description of the act. This is used in the documentation of your app
  # acl:    The access control list. See the ACL section below
  # get:    Handle GET requests
  # put:    Handle PUT requests
  # post:   Handle POST requests
  # patch:  Handle PATCH requests
  # delete: Handle DELETE requests
  # run:    A generic handler for any request method (for example if you want all PUT, POST, PATCH, and DELETE requests to go to the same handler).
  # ```
  #
  # ### ACL - Controlling access to your acts
  #
  # The ACL definition is very flexible. This means there are a lot of options.
  #
  # ```
  # No acl parameter            # The method is public
  # acl: nil                    # The method is public
  # acl: "*", "any", "public"   # The method is public
  # acl: "user"                 # Any logged-in user (anyone who logs in is in the group "user")
  # acl: [:admin, :manager]     # Anyone in the "admin" or "manager" group.
  # acl: %w(admin manager)      # Anyone in the "admin" or "manager" group.
  # # A hash with request methods as keys. Includes the keys "read" for GET and HEAD and "write" for PUT, POST, PATCH, DELETE.
  # acl: {
  #   get: "public",  # Anyone can GET.
  #   write: "admin"  # Only an admin can write
  # } 
  # # A proc that return boolean (true = access granted, false = access denied)
  # # The x variable is passed in.
  # acl: -> (x) { 
  #   x.req.env['X-Key'] == "Secret Key"
  # }
  # # Another example based on the client IP set by the proxy server
  # acl: -> (x) { 
  #   [x.req.env['X-Forwarded-For']].flatten.first == "10.20.40.80"
  # }
  # # Require a user to be in two groups
  # acl: -> (x) { 
  #   x.groups? :manager, :finance
  # }
  # ```
  def runs(opts=nil)
    @app ||= App.table_from_class(name).to_sym
    return App[@app] if opts.nil?
    App[@app] = opts
  end

  ##
  # Run a act in the current app.
  #
  # ```
  # module App::Person
  #   extend Waxx::Object
  #
  #   runs(
  #     default: 'list', 
  #     list: {
  #       desc: "List people (/person/list.json)",
  #       acl: "user",
  #       get: -> (x) {
  #         x << x.db.app.exec("SELECT * FROM person ORDER BY last_name, first_name").map{|r| r}.to_json
  #       }
  #     },
  #     everyone: {
  #       desc: "List everyone (/person/everyone.json)",
  #       acl: "user",
  #       get: -> (x) {
  #         # Run a different act in the same app
  #         run(x, :list, :get)
  #       }
  #     }
  #   )
  # end
  # ```
  def run(x, act, meth, *args)
    App[@app][act.to_sym][meth.to_sym][x, *args]
  end

  # Shortcut to Waxx.debug
  def debug(str, level=3)
    Waxx.debug(str, level)
  end

end
