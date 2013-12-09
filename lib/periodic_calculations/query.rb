module PeriodicCalculations
  class Query
    INTERVAL_UNIT = [:day, :week, :month, :year]

    # TODO:
    #  * prepared statement?

    # Builds a periodic operation query with PostgresSQL window functions
    #
    # @param relation [ActiveRecord::Relation] Object to build query from
    # @param query_options [QueryOptions]
    # @return [Array<Array>] for each period the time of the interval and the count of it
    def initialize(relation, query_options)
      @relation = relation
      @target_column = query_options.target_column
      @timestamp_column = query_options.timestamp_column
      @operation = query_options.operation.upcase
      @window_function = query_options.cumulative ? "ORDER" : "PARTITION"
      @inside_operation = query_options.operation == :count ? "SUM" : query_options.operation.upcase
      @binds = {
        :unit     => query_options.interval_unit,
        :interval => "1 #{query_options.interval_unit.upcase}",
        :start    => query_options.window_start,
        :end      => query_options.window_end,
        :offset   => "#{query_options.timezone_offset} seconds"
      }
    end

    def execute
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute(sanitized_sql).map do |elem|
          [Date.parse(elem["frame"]).to_time, elem["result"].to_i]
        end
      end
    end

    def to_sql
      sanitized_sql
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
      # 2. trim out unneeded rows if query is not cumulative
      # 3. make a union to add possible missing time points
      # 4. iterate over a window function that can cumulate the previous counters if needed
      # 5. trim out rows outside the time window
      #    Cannot be done before in the same query because window function iterates after the
      #    where/group by/having clauses (could be improved for non cumulative queries)

      <<-SQL
        WITH
          -- generate series within window
          -- (with shifted timezones utc_date -> zone_date)
          grid AS (
            SELECT  date_trunc(:unit, serie) AS frame,
                    NULL::integer            AS result
            FROM    generate_series(
                      :start::timestamp + INTERVAL :offset,
                      :end::timestamp + INTERVAL :offset,
                      :interval
                    )                                 AS serie
          )

          -- preprocess results grouping by interval
          -- (with shifted timezones utc_date -> zone_date)
          , preprocessed_results AS (
            #{relation_sql}
          )

          -- running window function calculate results and fill up gaps
          , results AS (
            SELECT  DISTINCT frame,
                    #{@inside_operation}(result) OVER (#{@window_function} BY frame) AS result
            FROM (
              SELECT frame, result FROM preprocessed_results
              UNION ALL
              SELECT frame, result FROM grid
            ) AS fulfilled_gaps
          )

        -- cut out values outside window
        -- (with shifted timezones utc_date -> zone_date)
        SELECT    frame,
                  result
        FROM      results
        WHERE     frame BETWEEN
                    date_trunc(:unit, :start::timestamp + INTERVAL :offset)
                    AND
                    date_trunc(:unit, :end::timestamp + INTERVAL :offset)
        ORDER BY  frame ASC
      SQL
    end

    def relation_sql
      # select frames an results
      relation_query = @relation
        .select(<<-SQL)
          date_trunc(:unit, #{@relation.table_name}.#{@timestamp_column} + INTERVAL :offset) AS frame,
          #{@operation}(#{@target_column}) AS result
        SQL

      # optimize selection if not cumulative query
      if @window_function == "PARTITION"
        relation_query = relation_query.where(<<-SQL)
          date_trunc(:unit, #{@relation.table_name}.#{@timestamp_column} + INTERVAL :offset) BETWEEN
            date_trunc(:unit, :start::timestamp + INTERVAL :offset)
            AND
            date_trunc(:unit, :end::timestamp + INTERVAL :offset)
        SQL
      end

      # group results by frames
      relation_query = relation_query.group(<<-SQL)
        date_trunc(:unit, #{@relation.table_name}.#{@timestamp_column} + INTERVAL :offset)
      SQL

      relation_query.to_sql
    end

  end

end

ActiveRecord::Base.extend PeriodicCalculations