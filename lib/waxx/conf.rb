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
# The global Conf variable. ex:  Conf['site']['name']
# Data is set in etc/{env}/config.yaml
module Conf
  extend self

  ##
  # Internal class var for conf data
  attr :data

  ##
  # Load the yaml config file into the Conf module
  # Access variables with Conf['var1']['var2'] or Conf/:var1/:var2
  def load_yaml(base=ENV['PWD'], env="active")
    @data = ::YAML.load_file("#{base}/etc/#{env}/config.yaml")
  end

  ##
  # Get a Conf variable
  def [](n)
    @data[n]
  end

  ##
  # Set a conf variable
  def []=(n, v)
    @data[n] = v
  end

  ##
  # Get a Conf variable
  def /(n)
    @data[n.to_s] || @data[n.to_sym]
  end

end

