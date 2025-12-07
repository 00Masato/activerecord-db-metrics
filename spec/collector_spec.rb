# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecord::Db::Metrics::Collector do
  let(:collector) { described_class.new }

  describe '#initialize' do
    it 'initializes with zero query count' do
      expect(collector.results[:total_queries]).to eq(0)
    end

    it 'initializes with empty crud counts' do
      expect(collector.results[:crud_operations_by_table]).to be_empty
    end
  end

  describe '#start_monitoring and #stop_monitoring' do
    it 'subscribes and unsubscribes to sql.active_record events' do
      collector.start_monitoring
      expect(collector.instance_variable_get(:@subscriber)).not_to be_nil

      collector.stop_monitoring
      # After unsubscribe, the subscriber should still exist but be inactive
      expect(collector.instance_variable_get(:@subscriber)).not_to be_nil
    end
  end

  describe '#results' do
    it 'returns a hash with total_queries and crud_operations_by_table' do
      results = collector.results

      expect(results).to have_key(:total_queries)
      expect(results).to have_key(:crud_operations_by_table)
    end
  end

  describe 'SQL tracking' do
    before do
      collector.start_monitoring
    end

    after do
      collector.stop_monitoring
    end

    it 'tracks SELECT queries' do
      # Simulate a SQL notification (Rails 7.2+ format with row_count)
      payload = {
        sql: 'SELECT * FROM users',
        name: 'User Load',
        table_name: 'users',
        row_count: 5
      }

      ActiveSupport::Notifications.instrument('sql.active_record', payload)

      results = collector.results
      expect(results[:total_queries]).to eq(1)
      expect(results[:crud_operations_by_table][:users][:SELECT]).to eq(5)
    end

    it 'ignores SCHEMA queries' do
      payload = {
        sql: 'SELECT * FROM schema_migrations',
        name: 'SCHEMA'
      }

      ActiveSupport::Notifications.instrument('sql.active_record', payload)

      results = collector.results
      expect(results[:total_queries]).to eq(0)
    end

    it 'tracks INSERT queries using affected_rows' do
      payload = {
        sql: 'INSERT INTO users (name) VALUES ("test")',
        name: 'User Create',
        table_name: 'users',
        row_count: 0,
        affected_rows: 1
      }

      ActiveSupport::Notifications.instrument('sql.active_record', payload)

      results = collector.results
      expect(results[:total_queries]).to eq(1)
      expect(results[:crud_operations_by_table][:users][:INSERT]).to eq(1)
    end

    it 'tracks UPDATE queries using affected_rows' do
      payload = {
        sql: 'UPDATE users SET name = "updated" WHERE id = 1',
        name: 'User Update',
        table_name: 'users',
        row_count: 0,
        affected_rows: 3
      }

      ActiveSupport::Notifications.instrument('sql.active_record', payload)

      results = collector.results
      expect(results[:total_queries]).to eq(1)
      expect(results[:crud_operations_by_table][:users][:UPDATE]).to eq(3)
    end

    it 'tracks DELETE queries using affected_rows' do
      payload = {
        sql: 'DELETE FROM users WHERE id = 1',
        name: 'User Destroy',
        table_name: 'users',
        row_count: 0,
        affected_rows: 1
      }

      ActiveSupport::Notifications.instrument('sql.active_record', payload)

      results = collector.results
      expect(results[:total_queries]).to eq(1)
      expect(results[:crud_operations_by_table][:users][:DELETE]).to eq(1)
    end

    it 'tracks bulk INSERT using affected_rows' do
      payload = {
        sql: 'INSERT INTO users (name) VALUES ("user1"), ("user2"), ("user3")',
        name: 'User Create Many',
        table_name: 'users',
        row_count: 0,
        affected_rows: 3
      }

      ActiveSupport::Notifications.instrument('sql.active_record', payload)

      results = collector.results
      expect(results[:crud_operations_by_table][:users][:INSERT]).to eq(3)
    end
  end
end
