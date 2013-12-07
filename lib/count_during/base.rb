module CountDuring
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def count_during(options = {})
        Query.new(all, options).execute
      end
    end
  end
end