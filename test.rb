require "minitest/autorun"
require "./lib/waxx"

class TestWaxx < MiniTest::Test

  def test_init
    qs = "x=1;y=2"
    assert(Waxx::Http.query_string_to_hash(qs) == {"x"=>"1","y"=>"2"}) 
    assert(Waxx::Http.query_string_to_hash(qs) == {"x"=>"1","y"=>"3"}) 
  end
end

