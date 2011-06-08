# encoding: utf-8
$:.push File.expand_path( "../lib", __FILE__ )
require "has_flags/version"

Gem::Specification.new do |s|
  s.name        = "chrno_has_flags"
  s.version     = HasFlags::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = [ "Denis Diachkov" ]
  s.email       = [ "d.diachkov@gmail.com" ]
  s.homepage    = "http://larkit.ru"
  s.summary     = "Adds has_flags macro to ActiveRecord"

  s.files         = Dir[ "*", "lib/**/*" ]
  s.require_paths = [ "lib" ]

  s.add_runtime_dependency "chrno_core_ext", ">= 1.0"
  s.add_runtime_dependency "rails", ">= 3.0"
  s.add_runtime_dependency "activerecord", ">= 3.0"
end