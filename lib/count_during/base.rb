module CountDuring
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def count_during(options = {})
        DurationCount.new(scoped, options).execute
      end
    end
  end
end