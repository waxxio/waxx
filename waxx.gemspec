require File.expand_path('../lib/waxx/version', __FILE__)
Gem::Specification.new do |s|
  s.name    = "waxx"
  s.version = Waxx::Version

  s.required_ruby_version = '>= 2.0.0'

  s.author = "Dan Fitzpatrick"
  s.email  = "dan@waxx.io"
  s.summary = "A fast and flexible application development framework"
  s.description = "Waxx is a high performace REST/RPC hybrid web application development framework."
  s.post_install_message = "\n  Thanks for installing Waxx.\n  See <www.waxx.io> for more info.\n"
  s.homepage = "https://www.waxx.io/"
  s.license = 'Apache-2.0'

  s.executables   = ["waxx"]
  s.bindir        = ["bin"]
  s.require_paths = ["lib"]
  s.files         = `git ls-files bin lib skel *.md LICENSE`.split("\n")

  s.cert_chain  = ['certs/waxx.pem']
  s.signing_key = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/
end
