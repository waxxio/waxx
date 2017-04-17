require File.expand_path('../lib/waxx/version', __FILE__)
Gem::Specification.new do |s|
  s.name    = "waxx"
  s.version = Waxx::Version

  s.required_ruby_version = '>= 1.9.0'

  s.author = "Dan Fitzpatrick"
  s.email  = "dan+waxx@eparklabs.com"
  s.summary = "A fast and flexible application development framework"
  s.description = "Waxx is a high performace REST/RPC hybrid web application development framework."
  s.post_install_message = "Thanks for installing Waxx. See www.waxx.io for more info."
  s.homepage = "https://www.waxx.io/"
  s.license = 'Apache-2.0'

  s.executables   = ["waxx"]
  s.bindir        = ["bin"]
  s.require_paths = ["lib"]
  s.files         = `git ls-files bin lib *.md LICENSE`.split("\n")
end
