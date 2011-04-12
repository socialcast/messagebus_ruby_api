# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "messagebus/version"

Gem::Specification.new do |s|
  s.name        = "messagebus"
  s.version     = Messagebus::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["MessageBus dev team"]
  s.email       = ["messagebus@googlegroups.com"]
  s.homepage    = ""
  s.summary     = %q{Send email through MessageBus service}
  s.description = %q{Allows you to use the MessageBus API }

  s.rubyforge_project = "messagebus"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
