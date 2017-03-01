# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

module Waxx::Util
  extend self

  def camel_case(str)
    title_case(str.to_s.gsub(/[\._-]/,' ')).gsub(' ','')
  end

  alias camelize camel_case

  def label(str)
    title_case(humanize(str.to_s))
  end

  def humanize(str)
    underscore(str.to_s).gsub('_',' ').capitalize
  end

  def title_case(str)
    str.to_s.split(' ').map{|t| t.capitalize}.join(' ')
  end

  alias titleize title_case

  def underscore(str)
    str.to_s.gsub(/::/, '_')
      .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      .gsub(/([a-z\d])([A-Z])/,'\1_\2')
      .tr("-", "_").tr(" ","_")
      .downcase
  end

  def app_from_class(cls)
    cls.to_s.split("::")[1]
  end

  def table_from_class(cls)
    underscore(app_from_class(cls))
  end

  def class_from_table(tbl)
    tbl.to_s.split("_").map{|i| i.capitalize}.join
  end

  def get_const(base_class, *names)
    names.inject(base_class){|c, n|
      c.const_get(n.to_s.split("_").map{|i| i.capitalize}.join)
    }
  end

  def qs(str)
    Waxx::Http.qs(str)
  end

end
