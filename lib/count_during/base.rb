module CountDuring
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def count_during(window_start, window_end, options = {})
        Query.new(all, window_start, window_end, options).execute
      end
    end
  end
end