module PeriodicCalculations
  class Engine < ::Rails::Engine
    ActiveRecord::Base.send(:include, PeriodicCalculations::Base)
  end
end