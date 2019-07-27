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

module Waxx

  ##
  # The Request Struct gets instanciated with each request (x.req)
  # ```
  # x.req.env   # A hash of the request environment
  # x.req.data  # The raw body of put, post, patch requests
  # x.req.meth  # Request method as a string: GET, PUT, POST, PATCH, DELETE
  # x.req.uri   # The URI 
  # x.req.get   # The GET/URL parameters (has with string keys and values) shortcut: x['name'] => 'value'
  # x.req.post  # The POST/BODY params with string keys and values) shortcut: x['name'] => 'value'
  # ```
  #
  # GET params can be delimited with & or ;. The following are equivilant:
  #
  # ```
  # http://localhost:7777/waxx/env?x=1&y=2&z=3
  # http://localhost:7777/waxx/env?x=1;y=2;z=3
  # ```
  #
  # Note that single params are single values and will be set to the last value received. 
  # Params names with "[]" appended are array values.
  #
  # ```
  # http://localhost:7777/waxx/env?foo=1;foo=2;foo=3
  # x['foo'] => "3"
  #
  # http://localhost:7777/waxx/env?foo[]=1;foo[]=2;foo[]=3
  # x['foo'] => ["1", "2", "3"]
  #
  # ```
  # If you are uploading JSON directly in the body (with the content type application/json or text/json), then the types are matched.
  #
  # Given the a request like:
  #
  # ```
  # Content-Type: application/json
  #
  # {foo:123,bar:['a','1',2]}
  # ```
  #
  # The following vars are of the type submitted
  #
  # ```
  # x['foo'] => 123 (as an int)
  # x['bar'] => ['a','1',2] (1 is a string and 2 is an int)
  # ```
  #
  # ### File Uploads
  # Given the form:
  #
  # ```
  # <form action="/file/upload" method="post" enctype="multipart/form-data">
  #   <input type="file" name="file">
  #   <button type="submit">Upload File</button>
  # </form>
  # ```
  #
  # The following hash is available (symbol keys):
  #
  # ```
  # x['file'][:filename] => 'file_name.ext'
  # x['file'][:data] => The content of the file
  # x['file'][:content_type] => The Content-Type as sent by the browser
  # x['file'][:headers] => An hash of other headers send by the browser regarding this file
  # ```
  #
  # How to save a file to the tmp folder:
  #
  # **app/file/file.rb**
  #
  # ```
  # module App::File
  #   extend Waxx::Object
  #   runs(
  #     upload: {
  #       desc: 'Upload a file to the tmp folder',
  #       post: -> (x) {
  #         # Strip any non-word chars and save the file to the tmp folder
  #         File.open("#{Waxx::Root}/tmp/(x/:file/:filename).gsub(/[\W\.]/,'-'),'wb'){|f| 
  #           f << x/:file/:data
  #         }
  #         x << "Your file has been uploaded."
  #       }
  #     }
  #   )
  # end
  # ```
  #
  Req = Struct.new(
    :env,
    :data,
    :meth,
    :uri,
    :get,
    :post,
    :cookies,
    :start_time
  )  

end

