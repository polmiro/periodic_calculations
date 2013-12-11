require 'coveralls'
Coveralls.wear!

ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'performance_matchers'

RSpec.configure do |config|
  config.filter_run_excluding :performance => true
end
