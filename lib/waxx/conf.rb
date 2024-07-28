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
# The global Waxx::Conf variable. ex:  `Waxx::Conf['site']['name']` or 
# shortcut `Waxx['site']['name']`
# Data is set in opt/env/config.yaml
module Waxx::Conf
  extend self

  ##
  # Internal class var for conf data
  attr :data
  @data = {}

  ##
  # Load the yaml config file into the Waxx module
  # Access variables with Waxx['var1']['var2'] or Waxx/:var1/:var2
  def load_yaml(base=ENV['PWD'], env="active")
    env = "dev" if env == "active" and not File.exist? "#{base}/opt/active"
    @data = ::YAML.load_file("#{base}/opt/#{env}/config.yaml")
  end

  ##
  # Get a Waxx variable
  def [](n)
    @data[n.to_s]
  end

  ##
  # Set a conf variable
  def []=(n, v)
    @data[n.to_s] = v
  end

  ##
  # Get a Waxx variable
  def /(n)
    @data[n.to_s]
  end

end

