# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Session
  extend self

  # Return a random string with no confusing chars (0Oo1Il etc)
  def random_password(size=10)
    random_string(size, :chars, 'ABCDEFGHJKLMNPQRSTUVWXYabcdefghkmnpqrstuvwxyz23456789@#%^&*i-_+=')
  end

  def login_needed(x)
    if x.ext == "json"
    else
      App::Html.render(x,
        title: "Please Login",
        #message: {type:"info", message: "Please login"},
        content: App::Usr::Html.login(x, return_to: x.req.uri)
      )
    end
  end
end
