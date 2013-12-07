module PeriodicCalculations
  class LazyQuery
    def initialize(query)
      @query = query
      @executed = false
      @result = nil
    end

    def method_missing(method_name, *args, &block)
      if method_name == :to_sql
        @query.to_sql
      else
        lazy_result.send(method_name, *args, &block)
      end
    end

    def respond_to?(method_name, include_private = false)
      method_name == :to_sql || super || lazy_result.respond_to?(method_name)
    end

    def result
      lazy_result
    end

    private

    def lazy_result
      if @executed
        @result
      else
        @executed = true
        @result = @query.execute
      end
    end
  end
end