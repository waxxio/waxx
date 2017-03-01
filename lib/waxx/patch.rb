# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

# Patches to Ruby Classes
class Date
  def h
    to_s.h
  end
  def f(format='%d-%b-%Y')
    strftime format
  end
end
class FalseClass
  def h
    "false"
  end
  def f(format=:yn)
    case format.to_sym
      when :yn
        "No"
      when :tf
        "False"
      when :icon
        '<span class="glyphicon glyphicon-minus" aria-hidden="true"></span>'
      when :num
        "0"
      else
        raise "Unknown format in FalseClass.f: #{format}. Needs to be :yn, :tf, :icon, or :num."
    end
  end
  def to_i
    0
  end
end
class Hash
  def _(k)
    self[k] || self[k.to_s]
  end
  def /(k)
    self[k.to_sym] || self[k.to_s]
  end
end
class NilClass
  def h
    ""
  end
  def f(size=2, zero_as="", t=",", d=".")
    zero_as
  end
  def to_sym
    "".to_sym
  end
end
class Numeric
  def h
    self
  end
  def f(size=2, zero_as="", t=",", d=".")
    return zero_as if zero?
    num_parts = to_s.split(".")
    x = num_parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{t}")
    return x if size == 0
    x << (d + (num_parts[1].to_s + "0000000")[0,size])
  end
end
class String
  def h
    gsub(/[&\"<>]/, {'&'=>'&amp;', '"'=>'&quot;', '<'=>'&lt;', '>'=>'&gt;'})
  end
  def f(size=2, zero_as="", t=",", d=".")
    return zero_as if to_f.zero?
    num_parts = split(".")
    x = num_parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{t}")
    return x if size == 0
    x << (d + (num_parts[1].to_s + "0000000")[0,size])
  end
end
class TrueClass
  def h
    "true"
  end
  def f(format=:yn)
    case format.to_sym
      when :text
        "True"
      when :icon
        '<span class="glyphicon glyphicon-ok" aria-hidden="true"></span>'
      when :num
        "1"
      else
        raise "Unknown format in TrueClass.f: #{format}. Needs to be :yn, :tf, :icon, or :num."
    end
  end
  def to_i
    1
  end
end
class Time
  def h
    to_s.h
  end
  def f(format='%d-%b-%Y')
    strftime format
  end
end
