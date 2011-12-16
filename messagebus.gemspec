# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "messagebus_ruby_api/version"

Gem::Specification.new do |s|
  s.name        = "messagebus_ruby_api"
  s.version     = MessagebusApi::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Messagebus dev team"]
  s.email       = ["messagebus@googlegroups.com"]
  s.homepage    = ""
  s.summary     = %q{Send email through Messagebus service}
  s.description = %q{Allows you to use the Messagebus API }

  s.rubyforge_project = "messagebus_ruby_api"

  s.files         = Dir.glob("{lib,spec}/**/*") + %w(README.rdoc Gemfile Rakefile .rvmrc)
  s.test_files    = Dir.glob("{spec}/**/*")
  s.executables   = []
  s.require_paths = ["lib"]

  s.license = 'APACHE2'
end
