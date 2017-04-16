# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Html
  extend self
  attr :view

  def view
    @view ||= name.split("::").slice(1,2).inject(App){|c, n| c.const_get(n)}
  end

  def f v, *fmt
    v.f *fmt
  end

  def h v
    begin
      v.h
    rescue
      v.to_s.h
    end
  end

  def qs v
    Waxx::Http.qs(v)
  end

  def debug(str, level=3)
    Waxx.debug(str, level)
  end

end

