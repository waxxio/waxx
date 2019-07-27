# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Json
  extend self
  def get(x, d, message:{})
    if PG::Result === d
      x << d.map{|r| r}.to_json
    else
      x << d.to_json
    end
  end
  alias :post :get
  alias :put :get
  alias :patch :get
  def delete(x, message:{})
    x << {ok: true, type: message[:type], message: message[:message]}.to_json
  end
  def not_found(x, data:{}, message:{})
    x.res.status = 404
    x << {ok: false, type: message[:type], message: message[:message]}.to_json
  end
end
