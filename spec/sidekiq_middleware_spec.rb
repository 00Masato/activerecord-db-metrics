# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecord::Db::Metrics::SidekiqMiddleware do
  let(:middleware) { described_class.new }
  let(:worker) { double('worker') }
  let(:queue) { 'default' }
  let(:logger) { instance_double(Logger, info: nil) }

  before do
    stub_const('Rails', double('Rails', logger: logger))
  end

  def run_middleware(job, &block)
    middleware.call(worker, job, queue, &block)
  end

  describe '#call' do
    it 'yields to execute the job' do
      job_executed = false
      run_middleware({ 'class' => 'MyJob' }) { job_executed = true }
      expect(job_executed).to be true
    end

    it 'logs metrics after job execution' do
      job = { 'class' => 'MyJob' }
      log_output = []
      allow(logger).to receive(:info) { |msg| log_output << msg }

      run_middleware(job) do
        payload = {
          sql: 'SELECT * FROM users',
          name: 'User Load',
          table_name: 'users',
          row_count: 3
        }
        ActiveSupport::Notifications.instrument('sql.active_record', payload)
      end

      expect(log_output).to include(a_string_matching(/DB Metrics for Job: MyJob/))
      expect(log_output).to include(a_string_matching(/Total DB Queries: 1/))
      expect(log_output).to include(a_string_matching(/\[USERS\]/))
    end

    it 'tracks queries executed during the job' do
      job = { 'class' => 'MyJob' }
      logged_results = nil

      allow(middleware).to receive(:log_db_metrics) do |_job_class, results|
        logged_results = results
      end

      run_middleware(job) do
        payload = {
          sql: 'INSERT INTO orders (user_id) VALUES (1)',
          name: 'Order Create',
          table_name: 'orders',
          affected_rows: 2
        }
        ActiveSupport::Notifications.instrument('sql.active_record', payload)
      end

      expect(logged_results[:total_queries]).to eq(1)
      expect(logged_results[:crud_operations_by_table][:orders][:INSERT]).to eq(2)
    end

    it 'does not track queries outside the job' do
      job = { 'class' => 'MyJob' }
      logged_results = nil

      allow(middleware).to receive(:log_db_metrics) do |_job_class, results|
        logged_results = results
      end

      # Query before job
      before_payload = { sql: 'SELECT * FROM users', name: 'User Load', table_name: 'users', row_count: 1 }
      ActiveSupport::Notifications.instrument('sql.active_record', before_payload)

      run_middleware(job) { nil }

      expect(logged_results[:total_queries]).to eq(0)
    end
  end
end
