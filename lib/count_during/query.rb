module CountDuring
  class Query
    INTERVAL_UNIT = [:day, :week, :month, :year]

    # Builds a duration count query with PostgresSQL window functions
    #
    # TODO:
    #  * Rails 4 compatible only right now (scoped vs all)
    #  * prepared statement ?
    #  * non-cumulative query doesn't need subquery
    #  * allow any aggregate function

    # Builds a duration count query
    #
    # @param relation [ActiveRecord::Relation] Object to build query from
    # @param window_start [DateTime] The window period start
    # @param window_end [DateTime] The window period end
    # @option options [Symbol] :interval_unit (:day) period of the counts
    # @option options [Boolean] :cumulative If the query should accumulate counts over time
    # @return [Array<Array>] for each period the time of the interval and the count of it
    def initialize(relation, window_start, window_end, options = {})
      @relation = relation

      @window_start = window_start.utc
      @window_end = window_end.utc
      @interval_unit = options[:interval_unit] || :day
      @cumulative = !!options[:cumulative]

      unless INTERVAL_UNIT.include?(@interval_unit)
        raise ArgumentError.new("Invalid interval unit")
      end
    end

    def execute
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute(sanitized_sql).map do |elem|
          [Date.parse(elem["unit"]).to_time, elem["count_unit"].to_i]
        end
      end
    end

    private

    def sanitized_sql
      ActiveRecord::Base.send(:sanitize_sql_array, [Arel.sql(sql), binds])
    end

    def sql
      # How are timezones managed
      # * Take into account the timezone offset throughout the search,
      #   so that the periods are correctly grouped.
      # * Restore the timezone at the very end to return the date in UTC
      #   being consistent with the Rails convention

      # result set sql with interval date
      # (using shifted timezones utc_date -> zone_date)
      sanitized_result_set_sql = @relation.select("date_trunc('#{@interval_unit}', activities.created_at + INTERVAL :timezone_offset) as unit, COUNT(*) AS count_unit").to_sql

      # 1. group currently selected rows by the interval
      # 2. make a union to add possible missing rows for empty days
      # 3. iterate over a window function that can cumulate the previous counters if needed
      # 4. trim out the unneeded rows using outside the time window
      #    Cannot be done before in the same query because window function iterates after the
      #    where/group by/having clauses

      <<-SQL
        SELECT unit, count_unit
        FROM
        (
          SELECT DISTINCT unit,
                 SUM(count_unit) OVER (#{sanitized_window_function} BY unit) AS count_unit
          FROM
          (
            #{sanitized_result_set_sql}

            -- group results by date (with shifted timezones utc_date -> zone_date)
            GROUP BY date_trunc(:interval_unit, activities.created_at + INTERVAL :timezone_offset)

            UNION ALL

            -- generate series within window (with shifted timezones utc_date -> zone_date)
            SELECT date_trunc(:interval_unit, serie) AS unit, 0 AS count_unit
            FROM generate_series(:window_start::timestamp + INTERVAL :timezone_offset, :window_end::timestamp + INTERVAL :timezone_offset, :interval) AS serie
          ) AS all_dates_results
        ) AS unbounded_results
        WHERE
          -- cut down with shifted input dates (utc date -> zone date)
          unit BETWEEN
            date_trunc(:interval_unit, :window_start::timestamp + INTERVAL :timezone_offset)
            AND
            date_trunc(:interval_unit, :window_end::timestamp + INTERVAL :timezone_offset)
        ORDER BY unit
      SQL
    end

    def binds
      @binds ||= {
        :interval_unit   => @interval_unit,
        :interval        => "1 #{@interval_unit.upcase}",
        :window_start    => @window_start,
        :window_end      => @window_end,
        :timezone_offset => "#{Time.now.in_time_zone.utc_offset} seconds"
      }
    end

    # Retrieve the correspondant PostgreSQL window function
    def sanitized_window_function
      @cumulative ? "ORDER" : "PARTITION"
    end

  end

end

ActiveRecord::Base.extend CountDuring