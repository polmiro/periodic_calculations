module PeriodicCalculations
  class Query
    INTERVAL_UNIT = [:day, :week, :month, :year]

    # TODO:
    #  * prepared statement?
    #  * non-cumulative query doesn't need subquery
    #  * allow any aggregate function

    # Builds a duration count query with PostgresSQL window functions
    #
    # @param relation [ActiveRecord::Relation] Object to build query from
    # @param query_options [QueryOptions]
    # @return [Array<Array>] for each period the time of the interval and the count of it
    def initialize(relation, query_options)
      @relation = relation
      @binds = {
        :interval_unit   => query_options.interval_unit,
        :interval        => "1 #{query_options.interval_unit.upcase}",
        :window_start    => query_options.window_start,
        :window_end      => query_options.window_end,
        :window_function => (query_options.cumulative ? "ORDER" : "PARTITION"),
        :timezone_offset => "#{query_options.timezone_offset} seconds"
      }
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
      ActiveRecord::Base.send(:sanitize_sql_array, [Arel.sql(sql), @binds])
    end

    def sql
      # How are timezones managed?
      # * Take into account the timezone offset throughout the search,
      #   so that the periods are correctly grouped.
      # * Restore the timezone at the very end to return the date in UTC
      #   being consistent with the Rails convention

      # What does it do?
      # 1. group currently selected rows by the interval
      # 2. make a union to add possible missing time points
      # 3. iterate over a window function that can cumulate the previous counters if needed
      # 4. trim out rows outside the time window
      #    Cannot be done before in the same query because window function iterates after the
      #    where/group by/having clauses (could be improved for non cumulative queries)

      sanitized_result_set_sql = @relation.select("date_trunc('#{@binds[:interval_unit]}', activities.created_at + INTERVAL :timezone_offset) as unit, COUNT(*) AS count_unit").to_sql

      <<-SQL
        SELECT unit, count_unit
        FROM
        (
          SELECT DISTINCT unit,
                 SUM(count_unit) OVER (#{@binds[:window_function]} BY unit) AS count_unit
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

  end

end

ActiveRecord::Base.extend PeriodicCalculations