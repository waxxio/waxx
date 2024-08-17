# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

# Patches to Ruby Classes
class BigDecimal
  def to_json(*a)
    to_f.to_json(*a)
  end
end
class Date
  # HTML format for a date
  def h
    to_s.h
  end
  # Shortcut to format a date in strftime
  def f(format='%d-%b-%Y')
    strftime format
  end
end
class FalseClass
  # HTML format "false"
  def h
    "false"
  end
  # Format to a selected format (see TrueClass also)
  #   Format Options:
  #     yn: No
  #     tf: False
  #     icon: glyphicon (Bootstrap)
  #     num: 0
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
  # Show false as zero
  def to_i
    0
  end
end
class Hash
  # Add an symbol/string indifferent access to a hash
  def /(k)
    return self[k.to_sym] if self.has_key?(k.to_sym)
    self[k.to_s]
  end
end
class NilClass
  # HTML format
  def h
    ""
  end
  # Format nil as and empty string (2nd param)
  # This is mostly for nil values out of the database
  # that have a format f() called on them.
  def f(size=2, zero_as="", t=",", d=".")
    zero_as
  end

  # Convert a nil to an empty symbol
  def to_sym
    "".to_sym
  end
  # Nil is empty
  def empty?
    true
  end
  def any?
    false
  end
end
class Numeric
  # HTML format (self -- no escaping needed)
  def h
    self
  end
  # Format a number
  #   size: number of decimal places
  #   zero_as: will display zero as "" (blank), "-" (dash), etc.
  #   t: thousands seperator
  #   d: decimal seperator
  def f(size=2, zero_as="", t=",", d=".")
    return zero_as if zero?
    num_parts = to_s.split(".")
    x = num_parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{t}")
    return x if size == 0
    x << (d + (num_parts[1].to_s + "0000000")[0,size])
  end
  def ordinal
    case self % 100
    when 11, 12, 13 then "#{self}th"
    else
      case self % 10
      when 1 then "#{self}st"
      when 2 then "#{self}nd"
      when 3 then "#{self}rd"
      else "#{self}th"
      end
    end
  end
end
class String
  # Escape HTML entities
  def h
    gsub(/[&\"<>]/, {'&'=>'&amp;', '"'=>'&quot;', '<'=>'&lt;', '>'=>'&gt;'})
  end
  # Convert a string to a number and format 
  # See Numeric.f()
  def f(size=2, zero_as="", t=",", d=".")
    return zero_as if to_f.zero?
    num_parts = split(".")
    x = num_parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{t}")
    return x if size == 0
    x << (d + (num_parts[1].to_s + "0000000")[0,size])
  end
  # Capitalize all words
  def capitalize_all
    split(/[ _]/).map{|l| l.capitalize}.join(' ')
  end
  alias title_case capitalize_all
  def any?
    self != ""
  end
end
class Time
  # HTML format
  def h
    to_s.h
  end
  # Format time in strftime
  def f(format='%d-%b-%Y')
    strftime format
  end
end
class TrueClass
  def h
    "true"
  end
  # Format to a selected format (see FalseClass also)
  #   Format Options:
  #     yn: Yes
  #     tf: True
  #     icon: glyphicon (Bootstrap)
  #     num: 1
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
  # Show true as 1
  def to_i
    1
  end
end
