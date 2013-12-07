module CountDuring
  class Engine < ::Rails::Engine
    ActiveRecord::Base.send(:include, CountDuring::Base)
  end
end