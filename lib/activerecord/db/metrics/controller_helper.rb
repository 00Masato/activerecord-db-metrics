# frozen_string_literal: true

module ActiveRecord
  module Db
    module Metrics
      # Helper module to be included in Rails controllers
      # Provides convenient methods to measure database operations
      #
      # @example Basic usage
      #   class ApplicationController < ActionController::Base
      #     include ActiveRecord::Db::Metrics::ControllerHelper
      #     around_action :measure_db_operations
      #   end
      module ControllerHelper
        extend ActiveSupport::Concern

        private

        # Measure database operations for the current action
        # This method should be used as an around_action filter
        def measure_db_operations
          metrics = Collector.new
          metrics.start_monitoring

          yield # Execute the action

          metrics.stop_monitoring
          results = metrics.results

          log_db_metrics(results)
        end

        # Log database metrics
        # Override this method in your controller to customize logging behavior
        #
        # @param results [Hash] Metrics results containing :total_queries and :crud_operations_by_table
        def log_db_metrics(results)
          Rails.logger.info "--- DB Metrics for Request ---"
          Rails.logger.info "Total DB Queries: #{results[:total_queries]}"

          # Show breakdown by table
          results[:crud_operations_by_table].each do |table, counts|
            operations = %i[INSERT SELECT UPDATE DELETE].map do |op|
              "#{op.to_s[0]}:#{counts[op]}"
            end.join(", ")
            total = counts.values.sum
            Rails.logger.info "  [#{table.upcase}] #{operations} (Total: #{total})"
          end

          Rails.logger.info "------------------------------"
        end
      end
    end
  end
end
