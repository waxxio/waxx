module Waxx
  def test_waxx_app
    # Setup x vars for different situations
    Waxx::App.init
    x_guest = Waxx::Test.x_nonuser
    x_admin = Waxx::Test.x_user
    x_admin.usr['grp'] = ["admin"]
    handler = {
      test: {
        desc: "A test handler",
        get: -> (x, n){
          "get #{n}"
        }
      }
    }

    # Run tests (returns a hash)
    Waxx::Test.test(Waxx::App,

      "access?" => {
        "nil" => [Waxx::App.access?(x_guest), expect: true],
        "asterisk" => [Waxx::App.access?(x_guest, acl:"*"), expect: true],
        "all" => [Waxx::App.access?(x_guest, acl:"all"), expect: true],
        "any" => [Waxx::App.access?(x_guest, acl:"any"), expect: true],
        "user" => [Waxx::App.access?(x_guest, acl:"user"), expect: false],
        "non-user-admin" => [Waxx::App.access?(x_guest, acl:"admin"), expect: false],
        "non-user-array-of-admin-other" => [Waxx::App.access?(x_guest, acl:%w(admin other)), expect: false],
        "proc-true" => [Waxx::App.access?(x_guest, acl: ->(x){true}), expect: true],
        "proc-false" => [Waxx::App.access?(x_guest, acl: ->(x){false}), expect: false],
        "admin-admin" => [Waxx::App.access?(x_admin, acl:"admin"), expect: true],
        "admin-array-of-admin-other" => [Waxx::App.access?(x_admin, acl:%w(admin other)), expect: true],
      },

      "not_found" => {
        "message" => [Waxx::App.not_found(x_guest, message:"not found"), run: -> (x) {x.res == "not found"}, args: [x_guest]]
      },

      "runs" => {
        "with-opts" => [(Waxx::App.init; Waxx::App[:test_app_handler] = handler), expect: handler],
        "with-name" => [Waxx::App[:test_app_handler], expect: handler],
        "run" => [Waxx::App.run(x_guest, :test_app_handler, :test, :get, [1]), expect: "get 1"],
      }

    )
  end
end

