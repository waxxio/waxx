# Waxx Copyright (c) 2016 ePark labs Inc. & Daniel J. Fitzpatrick <dan@eparklabs.com> All rights reserved.
# Released under the Apache Version 2 License. See LICENSE.txt.

##
# The test framework for waxx
#
# ## Usage:
#
#  
# ```
# module Waxx
#   def test_waxx_app
#     # Setup x vars for different situations
#     Waxx::App.init
#     x_guest = Waxx::Test.x_nonuser
#     x_admin = Waxx::Test.x_user
#     x_admin.usr['grp'] = ["admin"]
#     handler = {
#       test: {
#         desc: "A test handler",
#         get: -> (x, n){
#           "get #{n}"
#         }
#       }
#     }
#  
#     Waxx::Test.test(Waxx::App, # Module to test
#  
#       "access?" => {  # Method to test. 
#         # Each item below is a "test-name": [result value, 
#         #   expect: extepected-value, 
#         #   run: Proc to run that returns true on success, 
#         #   args: args to pass to the module method
#         # ]
#         "nil" => [Waxx::App.access?(x_guest), expect: true],
#         "asterisk" => [Waxx::App.access?(x_guest, acl:"*"), expect: true],
#         "all" => [Waxx::App.access?(x_guest, acl:"all"), expect: true],
#         "any" => [Waxx::App.access?(x_guest, acl:"any"), expect: true],
#         "user" => [Waxx::App.access?(x_guest, acl:"user"), expect: false],
#         "non-user-admin" => [Waxx::App.access?(x_guest, acl:"admin"), expect: false],
#         "non-user-array-of-admin-other" => [Waxx::App.access?(x_guest, acl:%w(admin other)), expect: false],
#         "proc-true" => [Waxx::App.access?(x_guest, acl: ->(x){true}), expect: true],
#         "proc-false" => [Waxx::App.access?(x_guest, acl: ->(x){false}), expect: false],
#         "admin-admin" => [Waxx::App.access?(x_admin, acl:"admin"), expect: true],
#         "admin-array-of-admin-other" => [Waxx::App.access?(x_admin, acl:%w(admin other)), expect: true],
#       },
#  
#       "not_found" => {
#         "message" => [Waxx::App.not_found(x_guest, message:"not found"), run: -> (x) {x.res == "not found"}, args: [x_guest]]
#       },
#  
#       "runs" => {
#         "with-opts" => [(Waxx::App.init; Waxx::App[:test_app_handler] = handler), expect: handler],
#         "with-name" => [Waxx::App[:test_app_handler], expect: handler],
#         "run" => [Waxx::App.run(x_guest, :test_app_handler, :test, :get, [1]), expect: "get 1"],
#       }
#  
#     )
# end
# ```
module Waxx::Test
  extend self

  ##
  # Setup and process a test on a module method
  def test(module_name, methods={})
    mod = module_name.to_s
    re = {mod => {}}
    methods.each{|meth, tests|
      re[mod][meth] = {}
      passed = 0
      tests.each{|test_name, args|
        begin
          re[mod][meth][test_name] = run_test(*args)
          passed += 1 if re[mod][meth][test_name]['status'] == 'pass'
        rescue => test_error
          re[mod][meth][test_name] = {
            "status" => "fail",
            "error" => {
              "got" => "ERROR",
              "message" => test_error.to_s,
              "backtrace" => test_error.backtrace
            }
          }
        end
      }
      re[mod][meth]['tests'] = tests.size
      re[mod][meth]['tests_passed'] = passed
      re[mod][meth]['test_performance'] = "#{((passed.to_f / tests.size) * 100).to_i}%"
    }
    re
  end
  
  ##
  # Run the test
  def run_test(got, expect:nil, run: nil, args:[])
    if run
      expect = true
      got = run.call(*args)
    end
    if got == expect
      {"status" => "pass"}
    else
      {"status" => "fail",
        "error" => {
          "got" => got,
          "expect" => expect
        }
      }
    end
  end

  # A mock request skeleton. Create and then edit with test-specific attrs
  def mock_req
    Waxx::Req.new(ENV, {}, 'GET', "/test/test/1", {}, {}, {}, Time.new).freeze
  end

  # A mock request with default values
  def mock_res(req)
    Waxx::Res.new("", 200, Waxx::Server.default_response_headers(req, "txt"), [], [], [])
  end

  # A logged-in user
  def x_user(req=mock_req, res=nil, db=nil) 
    res ||= mock_res(req)
    #x = Waxx::X.new(req, res, usr, ua, db, meth.downcase.to_sym, app, act, oid, args, ext, jobs).freeze
    Waxx::X.new(
			req,
			res,
			{'id' => 1, 'grp'=>['user']},
			{'id' => 1},
			db,
			:get,
			:test,
			:test,
			1,
			[1],
			"json",
			[]
		)
	end

  # A non-user/public/guest
  def x_nonuser(req=mock_req, res=nil, db=nil) 
    res ||= mock_res(req)
    Waxx::X.new(
			req,
			res,
			{'grp'=>[]},
			{},
			db,
			:get,
			:test,
			:test,
			1,
			[1],
			"json",
			[]
		)
	end
end

