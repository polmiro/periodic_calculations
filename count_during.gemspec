$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "count_during/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "count_during"
  s.version     = CountDuring::VERSION
  s.authors     = ["Pol"]
  s.email       = ["polmiro@gmail.com"]
  s.homepage    = ""
  s.summary     = "Retrieve table stats in periods of time"
  s.description = "Retrieve table stats in periods of time"
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails", ">= 3.2"
  s.add_dependency "railties"

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "pg"
  s.add_development_dependency "coveralls"
end
