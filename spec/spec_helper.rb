require 'coveralls'
Coveralls.wear!

ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'

RSpec.configure do |config|
  config.filter_run_excluding :performance => true
  config.before(:all, :performance => true) do
    require 'benchmark'
    require 'performance_matchers'
  end
end
