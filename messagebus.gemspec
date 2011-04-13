# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "messagebus/version"

Gem::Specification.new do |s|
  s.name        = "messagebus_ruby_api"
  s.version     = Messagebus::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Messagebus dev team"]
  s.email       = ["messagebus@googlegroups.com"]
  s.homepage    = ""
  s.summary     = %q{Send email through Messagebus service}
  s.description = %q{Allows you to use the Messagebus API }

  s.rubyforge_project = "messagebus_ruby_api"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
