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

# Libs (core & std lib)
require 'socket'
require 'thread'
require 'openssl'
require 'base64'
require 'json'
require 'time'
require 'fileutils'
require 'yaml'
# Require ruby files in waxx/ (except irb stuff)
require_relative 'waxx/waxx'
require_relative 'waxx/x'
require_relative 'waxx/req'
require_relative 'waxx/res'
require_relative 'waxx/app'
require_relative 'waxx/conf'
require_relative 'waxx/console'
require_relative 'waxx/csrf'
require_relative 'waxx/database'
require_relative 'waxx/encrypt'
require_relative 'waxx/error'
require_relative 'waxx/html'
require_relative 'waxx/http'
require_relative 'waxx/json'
require_relative 'waxx/object'
require_relative 'waxx/patch'
require_relative 'waxx/pdf'
require_relative 'waxx/process'
require_relative 'waxx/pg'
require_relative 'waxx/mysql2'
require_relative 'waxx/sqlite3'
require_relative 'waxx/server'
require_relative 'waxx/supervisor'
require_relative 'waxx/util'
require_relative 'waxx/view'


$:.unshift "#{File.dirname(__FILE__)}/.." 



