# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
bundle install

# Run all tests
rake spec

# Run a single spec file
bundle exec rspec spec/collector_spec.rb

# Lint
bundle exec rubocop

# Auto-fix lint issues
bundle exec rubocop -a

# Build gem
gem build activerecord-db-metrics.gemspec
```

## Architecture

This is a Rails gem that tracks database query metrics per request by subscribing to `ActiveSupport::Notifications` on the `sql.active_record` event.

### Core components

- **`Collector`** (`lib/activerecord/db/metrics/collector.rb`) — the main engine. Subscribes/unsubscribes to SQL notifications via `start_monitoring`/`stop_monitoring`, accumulates counts in `@crud_counts_by_table` (a nested Hash with default 0 for counts), and exposes `results` returning `{ total_queries:, crud_operations_by_table: }`.

- **`ControllerHelper`** (`lib/activerecord/db/metrics/controller_helper.rb`) — an `ActiveSupport::Concern` for Rails controllers. Provides `measure_db_operations` (used as `around_action`) and a default `log_db_metrics` that writes to `Rails.logger`. Override `log_db_metrics` to send to external services.

### Key design details

- **Row counts use Rails 7.2+ payload fields**: `payload[:row_count]` for SELECT, `payload[:affected_rows]` for INSERT/UPDATE/DELETE. This is why Rails >= 7.2 is required — not parsing SQL for row counts.
- **Table name resolution**: prefers `payload[:table_name]` (set by Rails for most queries), falls back to regex parsing of SQL for edge cases.
- **SCHEMA queries are excluded** by checking `payload[:name] != 'SCHEMA'`.
- **Counts track row counts, not query counts**: e.g., `insert_all` of 3 records increments INSERT by 3, not 1.

### Tests

Tests simulate SQL events directly via `ActiveSupport::Notifications.instrument('sql.active_record', payload)` without a real database, using the Rails 7.2 payload format (`row_count`, `affected_rows`).
