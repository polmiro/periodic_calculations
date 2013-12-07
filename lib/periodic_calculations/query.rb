module PeriodicCalculations
  class Query
    INTERVAL_UNIT = [:day, :week, :month, :year]

    # TODO:
    #  * prepared statement?
    #  * non-cumulative query doesn't need subquery
    #  * allow any aggregate function

    # Builds a periodic operation query with PostgresSQL window functions
    #
    # @param relation [ActiveRecord::Relation] Object to build query from
    # @param query_options [QueryOptions]
    # @return [Array<Array>] for each period the time of the interval and the count of it
    def initialize(relation, query_options)
      @relation = relation
      @interval_unit = query_options.interval_unit
      @column_name = query_options.column_name
      @window_function = window_function(query_options)
      @operation = query_options.operation.upcase
      @binds = {
        :interval_unit   => query_options.interval_unit,
        :interval        => "1 #{query_options.interval_unit.upcase}",
        :window_start    => query_options.window_start,
        :window_end      => query_options.window_end,
        :timezone_offset => "#{query_options.timezone_offset} seconds"
      }
    end

    def execute
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute(sanitized_sql).map do |elem|
          [Date.parse(elem["frame"]).to_time, elem["frame_result"].to_i]
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

      sanitized_result_set_sql = @relation.select("date_trunc('#{@interval_unit}', activities.created_at + INTERVAL :timezone_offset) as frame, #{@operation}(#{@column_name}) AS frame_result").to_sql

      <<-SQL
        SELECT frame, frame_result
        FROM
        (
          SELECT DISTINCT frame,
                 #{@operation}(frame_result) OVER (#{@window_function} BY frame) AS frame_result
          FROM
          (
            #{sanitized_result_set_sql}

            -- group results by date (with shifted timezones utc_date -> zone_date)
            GROUP BY date_trunc(:interval_unit, activities.created_at + INTERVAL :timezone_offset)

            UNION ALL

            -- generate series within window (with shifted timezones utc_date -> zone_date)
            SELECT date_trunc(:interval_unit, serie) AS frame, NULL AS frame_result
            FROM generate_series(:window_start::timestamp + INTERVAL :timezone_offset, :window_end::timestamp + INTERVAL :timezone_offset, :interval) AS serie
          ) AS all_dates_results
        ) AS unbounded_results
        WHERE
          -- cut down with shifted input dates (utc date -> zone date)
          frame BETWEEN
            date_trunc(:interval_unit, :window_start::timestamp + INTERVAL :timezone_offset)
            AND
            date_trunc(:interval_unit, :window_end::timestamp + INTERVAL :timezone_offset)
        ORDER BY frame
      SQL
    end

    def window_function(query_options)
      query_options.cumulative ? "ORDER" : "PARTITION"
    end

  end

end

ActiveRecord::Base.extend PeriodicCalculations