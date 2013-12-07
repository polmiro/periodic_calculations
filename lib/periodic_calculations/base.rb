module PeriodicCalculations
  module Base
    extend ActiveSupport::Concern

    # TODO:
    #  * Rails 4 compatible only right now (scoped vs all)

    module ClassMethods
      def periodic_count(*args)
        periodic_calculation(:count, *args)
      end

      def periodic_maximum(*args)
        periodic_calculation(:max, *args)
      end

      def periodic_minimum(*args)
        periodic_calculation(:min, *args)
      end

      def periodic_sum(*args)
        periodic_calculation(:sum, *args)
      end

      def periodic_average(*args)
        periodic_calculation(:avg, *args)
      end

      def periodic_calculation(operation, column_name, window_start, window_end, options = {})
        query_options = QueryOptions.new(operation, column_name, window_start, window_end, options)
        query = Query.new(all, query_options)
        query.execute
      end
    end
  end
end