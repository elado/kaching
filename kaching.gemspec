# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "kaching/version"

Gem::Specification.new do |s|
  s.name        = "kaching"
  s.version     = Kaching::VERSION
  s.authors     = ["Elad Ossadon"]
  s.email       = ["elad@ossadon.com"]
  s.homepage    = ""
  s.summary     = %q{Caches counters and lists of Rails ActiveRecord in an external storage such as Redis.}
  s.description = %q{Makes your DB suffer less from COUNT(*) queries and check-for-existence queries of associations (has_many and has_many :through), by keeping and maintaining counts and lists on Redis, for faster access.}

  s.rubyforge_project = "kaching"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', ">= 3.0.0"
  s.add_dependency 'redis'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3'
end
