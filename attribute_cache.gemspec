# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "attribute_cache/version"

Gem::Specification.new do |s|
  s.name        = "attribute_cache"
  s.version     = AttributeCache::VERSION
  s.authors     = ["Elad Ossadon"]
  s.email       = ["elad@ossadon.com"]
  s.homepage    = ""
  s.summary     = %q{Cache attributes of Rails ActiveRecord in an external storage such as Redis.}
  s.description = %q{Cache attributes of Rails ActiveRecord in an external storage such as Redis.}

  s.rubyforge_project = "attribute_cache"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_dependency 'rails', ">= 3.0.0"
  s.add_dependency 'activerecord', ">= 3.0.0"
  s.add_dependency 'redis'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
end
