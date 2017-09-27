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

##
# Waxx is a high-performance Ruby web application development framework. See https://www.waxx.io/ for more information.
module Waxx
  extend self

  # TODO: Figure this out based on the waxx command opts
  Root = Dir.pwd

  # A few helper functions

  ##
  # Shortcut to Waxx::Waxx variables
  def [](str)
    Waxx::Conf[str]
  end

  ##
  # Shortcut to Waxx::Waxx variables
  def /(str)
    Waxx::Conf/str
  end

  ##
  # Output to the log
  #   Waxx.debug(
  #     str,          # The text to output
  #     level         # The number 0 (most important) - 9 (least important)
  #   )
  #   # Set the level in config.yaml (debug.level) of what level or lower to ouutput
  def debug(str, level=3)
    puts str.to_s if level <= Waxx['debug']['level'].to_i
  end

  ##
  # Get a pseudo-random (non-cryptographically secure) string to use as a temporary password.
  # If you need real random use SecureRandom.random_bytes(size) or SecureRandom.base64(size).
  #  1. size: Length of string
  #  2. type: [
  #       any: US keyboard characters
  #       an:  Alphanumeric (0-9a-zA-Z)
  #       anl: Alphanumeric lower: (0-9a-z)
  #       chars: Your own character list
  #     ]
  #  3. chars: A string of your own characters
  def random_string(size=32, type=:an, chars=nil)
    if not type.to_sym == :chars
      types = {
        any: '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz~!@#$%^&*()_-+={[}]|:;<,>.?/',
        an: '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
        anl: '0123456789abcdefghijklmnopqrstuvwxyz'
      }
      chars = types[type.to_sym].split("")
    end
    opts = chars.size
    1.upto(size).map{chars[rand(opts)]}.join
  end

end

