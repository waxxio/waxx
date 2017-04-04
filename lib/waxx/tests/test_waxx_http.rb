
module Waxx
  def test_waxx_http
   
    utc = Time.new.utc

    Waxx::Test.test(Waxx::Http,
      "query_string_to_hash" => {
        "single-value" => [Waxx::Http.query_string_to_hash("x=1"), expect: {"x"=>"1"}],
        "double-value-ampersand" => [Waxx::Http.query_string_to_hash("x=1&y=2"), expect: {"x"=>"1","y"=>"2"}],
        "double-value-semicolon" => [Waxx::Http.query_string_to_hash("x=1;y=2"), expect: {"x"=>"1","y"=>"2"}],
        "empty-value" => [Waxx::Http.query_string_to_hash("x=1;y=;z=3"), expect: {"x"=>"1","y"=>"", "z"=>"3"}],
        "name-only" => [Waxx::Http.query_string_to_hash("x"), expect: {"x"=>""}],
        "empty" => [Waxx::Http.query_string_to_hash(""), expect: {}],
        "nil" => [Waxx::Http.query_string_to_hash(nil), expect: {}],
      },
      "ctypes" => {
        "html" => [Waxx::Http.ctype("html"), expect: "text/html; charset=utf-8"],
        "json" => [Waxx::Http.ctype("json"), expect: "application/json; charset=utf-8"],
        "xlsx" => [Waxx::Http.ctype("xlsx"), expect: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"],
        "pdf" => [Waxx::Http.ctype("pdf"), expect: "application/pdf"],
      },
      "time" => {
        "format" => [Waxx::Http.time(utc), expect: utc.strftime('%a, %d %b %Y %H:%M:%S UTC')]
      }
    )
  end
end

