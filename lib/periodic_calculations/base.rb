module PeriodicCalculations
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def periodic_count_all(*args)
        periodic_calculation(:count, "*", *args)
      end

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
        current_scope = Rails::VERSION::MAJOR >= 4 ? all : scoped
        query = Query.new(current_scope, query_options)
        LazyQuery.new(query)
      end
    end
  end
end