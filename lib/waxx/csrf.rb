# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Csrf
  extend self

  def ok?(x)
    x['csrf'] == x.usr['uk']
  end

  def ht(x)
    %(<input type="hidden" name="csrf" value="#{x.usr['uk']}">)
  end
end
