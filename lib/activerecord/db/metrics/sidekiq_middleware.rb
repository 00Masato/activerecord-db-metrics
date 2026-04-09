# frozen_string_literal: true

module ActiveRecord
  module Db
    module Metrics
      # Sidekiq server middleware to measure database operations per job
      #
      # @example Setup
      #   Sidekiq.configure_server do |config|
      #     config.server_middleware do |chain|
      #       chain.add ActiveRecord::Db::Metrics::SidekiqMiddleware
      #     end
      #   end
      class SidekiqMiddleware
        def call(_worker, job, _queue)
          collector = Collector.new
          collector.start_monitoring

          yield

          collector.stop_monitoring
          log_db_metrics(job['class'], collector.results)
        end

        private

        # Log database metrics for a job
        # Override this method in a subclass to customize logging behavior
        #
        # @param job_class [String] The job class name
        # @param results [Hash] Metrics results containing :total_queries and :crud_operations_by_table
        def log_db_metrics(job_class, results)
          Rails.logger.info "--- DB Metrics for Job: #{job_class} ---"
          Rails.logger.info "Total DB Queries: #{results[:total_queries]}"

          results[:crud_operations_by_table].each do |table, counts|
            operations = %i[INSERT SELECT UPDATE DELETE].map do |op|
              "#{op.to_s[0]}:#{counts[op]}"
            end.join(', ')
            total = counts.values.sum
            Rails.logger.info "  [#{table.upcase}] #{operations} (Total: #{total})"
          end

          Rails.logger.info '------------------------------'
        end
      end
    end
  end
end
