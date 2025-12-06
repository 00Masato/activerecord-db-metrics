# frozen_string_literal: true

module ActiveRecord
  module Db
    module Metrics
      # Collects and tracks database operation metrics during a request lifecycle
      class Collector
        CRUD_KEYWORDS = %w[INSERT UPDATE DELETE SELECT].freeze

        def initialize
          @query_count = 0
          # Track CRUD operations per table
          # Example: { users: { SELECT: 5, INSERT: 1 }, posts: { SELECT: 2 } }
          @crud_counts_by_table = Hash.new { |hash, key| hash[key] = Hash.new(0) }
        end

        # Subscribe to ActiveRecord SQL notifications
        def start_monitoring
          @subscriber = ActiveSupport::Notifications.subscribe("sql.active_record", log_subscriber)
        end

        # Unsubscribe from ActiveRecord SQL notifications
        def stop_monitoring
          ActiveSupport::Notifications.unsubscribe(@subscriber) if @subscriber
        end

        # Get collected metrics
        # @return [Hash] Hash containing :total_queries and :crud_operations_by_table
        def results
          {
            total_queries: @query_count,
            crud_operations_by_table: @crud_counts_by_table
          }
        end

        private

        def log_subscriber
          lambda do |_name, _start, _finish, _id, payload|
            next unless payload[:sql] && payload[:name] != "SCHEMA"

            @query_count += 1

            # 1. Identify operation type (INSERT, SELECT, etc.)
            operation = payload[:sql].strip.upcase.split.first

            next unless CRUD_KEYWORDS.include?(operation)

            # 2. Identify table name
            table_name = payload[:table_name] || extract_table_name_from_sql(payload[:sql], operation)

            next unless table_name

            # 3. Get actual row count and record it
            row_count = extract_row_count(payload, operation)
            @crud_counts_by_table[table_name.to_sym][operation.to_sym] += row_count
          end
        end

        # Extract actual row count from payload
        # Rails 7.2+ provides payload[:row_count] for all queries
        # See: https://github.com/rails/rails/pull/50887
        def extract_row_count(payload, _operation)
          payload[:row_count] || 0
        end

        # Extract table name from SQL as fallback when payload[:table_name] is unavailable
        def extract_table_name_from_sql(sql, operation)
          sql_downcase = sql.downcase

          case operation
          when "SELECT"
            # Pattern: SELECT "users".* FROM "users"
            match = sql_downcase.match(/from\s+["`]?(\w+)["`]?/)
            match[1] if match
          when "INSERT"
            # Pattern: INSERT INTO "users"
            match = sql_downcase.match(/insert\s+into\s+["`]?(\w+)["`]?/)
            match[1] if match
          when "UPDATE"
            # Pattern: UPDATE "users" SET
            match = sql_downcase.match(/update\s+["`]?(\w+)["`]?\s+set/)
            match[1] if match
          when "DELETE"
            # Pattern: DELETE FROM "users"
            match = sql_downcase.match(/delete\s+from\s+["`]?(\w+)["`]?/)
            match[1] if match
          end
        end
      end
    end
  end
end
