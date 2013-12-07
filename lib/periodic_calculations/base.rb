module PeriodicCalculations
  module Base
    extend ActiveSupport::Concern

    # TODO:
    #  * Rails 4 compatible only right now (scoped vs all)

    module ClassMethods
      def count_during(window_start, window_end, options = {})
        query_options = QueryOptions.new(window_start, window_end, options)
        query = Query.new(all, query_options)
        query.execute
      end
    end
  end
end