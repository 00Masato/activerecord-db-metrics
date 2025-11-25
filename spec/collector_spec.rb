# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::Db::Metrics::Collector do
  let(:collector) { described_class.new }

  describe "#initialize" do
    it "initializes with zero query count" do
      expect(collector.results[:total_queries]).to eq(0)
    end

    it "initializes with empty crud counts" do
      expect(collector.results[:crud_operations_by_table]).to be_empty
    end
  end

  describe "#start_monitoring and #stop_monitoring" do
    it "subscribes and unsubscribes to sql.active_record events" do
      expect(ActiveSupport::Notifications).to receive(:subscribe).with("sql.active_record", anything)
      collector.start_monitoring

      expect(ActiveSupport::Notifications).to receive(:unsubscribe).with(anything)
      collector.stop_monitoring
    end
  end

  describe "#results" do
    it "returns a hash with total_queries and crud_operations_by_table" do
      results = collector.results

      expect(results).to have_key(:total_queries)
      expect(results).to have_key(:crud_operations_by_table)
    end
  end

  describe "SQL tracking" do
    before do
      collector.start_monitoring
    end

    after do
      collector.stop_monitoring
    end

    it "tracks SELECT queries" do
      # Simulate a SQL notification
      payload = {
        sql: "SELECT * FROM users",
        name: "User Load",
        table_name: "users"
      }

      ActiveSupport::Notifications.instrument("sql.active_record", payload)

      results = collector.results
      expect(results[:total_queries]).to eq(1)
      expect(results[:crud_operations_by_table][:users][:SELECT]).to eq(1)
    end

    it "ignores SCHEMA queries" do
      payload = {
        sql: "SELECT * FROM schema_migrations",
        name: "SCHEMA"
      }

      ActiveSupport::Notifications.instrument("sql.active_record", payload)

      results = collector.results
      expect(results[:total_queries]).to eq(0)
    end
  end
end
