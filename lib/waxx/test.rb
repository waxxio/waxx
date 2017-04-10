module Waxx::Test
  extend self

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

  # Context factories
  def mock_req
    Waxx::Req.new(ENV, {}, 'GET', "/test/test/1", {}, {}, {}, Time.new).freeze
  end

  def mock_res(req)
    Waxx::Res.new("", 200, Waxx::Server.default_response_headers(req, "txt"), [], [], [])
  end

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

module Waxx::Test2
  extend self

  def test(mod, meth, tests)
    test_count = tests.length
    successful = 0
    re = {
      "module" => mod.to_s,
      "method" => meth,
      "tests" => []
    }
    
    tests.each{|t, opts|
      if Hash === opts and opts[:given]
        expect = opts[:expect]
        got = mod.send(meth, *(opts[:given]))
      else
        expect = opts
        got = mod.send(meth, t)
      end
      if Proc === expect
        if expect.call(*(opts[:given]))
          successful += 1
          re["tests"].push({"#{t}" => "pass"})
        else
          re["tests"].push({"#{t}" => "fail", "error" => "proc returned false: #{expect.inspect}"})
        end
      else
        if got == expect
          successful += 1
          re["tests"].push({"#{t}" => "pass"})
        else
          re["tests"].push({"#{t}" => "fail", "error" => "#{got} != #{expect}"})
        end
      end
    }

    re["successful"] = "#{((successful.to_f / test_count.to_f) * 100).to_i}%"
    puts re.to_yaml
  end

end


module Waxx::XTest
  extend self

  def test(name, &blk)
    puts "#{name}: "
    blk.call(name)
  end

  def with(name, &blk)
    print "  #{name}: "
    blk.call(name)
  end

  def eq(val1, val2)
    puts (val1 == val2 ? "pass" : "fail: #{val1} != #{val2}")
  end
 
end
