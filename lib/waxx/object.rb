# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Object

  attr :app

  def runs(opts=nil)
    @app ||= App.table_from_class(name).to_sym
    return App[@app] if opts.nil?
    App[@app] = opts
  end

  def run(x, act, meth, *args)
    App[@app][act.to_sym][meth.to_sym][x, *args]
  end

end
