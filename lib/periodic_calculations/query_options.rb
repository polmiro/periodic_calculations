module PeriodicCalculations
  class QueryOptions
    INTERVAL_UNIT = [:day, :week, :month, :year]

    attr_reader :window_start,
                :window_end,
                :interval_unit,
                :cumulative,
                :timezone_offset

    def initialize(window_start, window_end, options = {})
      @window_start = window_start
      @window_end = window_end
      @interval_unit = options[:interval_unit] || :day
      @cumulative = !!options[:cumulative]
      @timezone_offset = Time.now.in_time_zone.utc_offset

      validate!
    end

    private

    def validate!
      validate_window!
      validate_interval_unit!
    end

    def validate_window!
      unless window_start.is_a?(DateTime) && window_end.is_a?(DateTime)
        raise ArgumentError.new("Invalid DateTime window")
      end
    end

    def validate_interval_unit!
      unless INTERVAL_UNIT.include?(@interval_unit)
        raise ArgumentError.new("Invalid interval unit")
      end
    end
  end
end