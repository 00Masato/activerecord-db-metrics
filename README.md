# ActiveRecord::Db::Metrics

A lightweight gem to monitor and measure database queries in Rails applications. Track CRUD operations per table with support for bulk operations like `insert_all`.

## Features

- 📊 Track database queries per request
- 🔍 Breakdown by table and operation type (INSERT, SELECT, UPDATE, DELETE)
- 💪 Support for bulk operations (`insert_all`, `upsert_all`)
- 🪶 Lightweight with minimal performance overhead
- 🎯 Easy integration with Rails controllers

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-db-metrics'
```

And then execute:

```bash
bundle install
```

## Usage

### Basic Setup

Include the helper module in your controller and add the `around_action`:

```ruby
class ApplicationController < ActionController::Base
  include ActiveRecord::Db::Metrics::ControllerHelper
  around_action :measure_db_operations
end
```

Now, every request will log database metrics like this:

```
--- DB Metrics for Request ---
Total DB Queries: 15
  [USERS] I:1, S:10, U:2, D:0 (Total: 13)
  [POSTS] I:0, S:2, U:0, D:0 (Total: 2)
------------------------------
```

### Selective Monitoring

You can apply metrics to specific controllers or actions:

```ruby
class UsersController < ApplicationController
  include ActiveRecord::Db::Metrics::ControllerHelper
  around_action :measure_db_operations, only: [:index, :show]
end
```

### Custom Logging

Override the `log_db_metrics` method to customize logging behavior:

```ruby
class ApplicationController < ActionController::Base
  include ActiveRecord::Db::Metrics::ControllerHelper
  around_action :measure_db_operations

  private

  def log_db_metrics(results)
    # Send to your monitoring service
    StatsD.gauge('db.queries.total', results[:total_queries])

    results[:crud_operations_by_table].each do |table, counts|
      counts.each do |operation, count|
        StatsD.gauge("db.queries.#{table}.#{operation.downcase}", count)
      end
    end
  end
end
```

### Manual Usage

You can also use the collector directly without the controller helper:

```ruby
collector = ActiveRecord::Db::Metrics::Collector.new
collector.start_monitoring

# Your database operations here
User.all
User.create(name: "Alice")

collector.stop_monitoring
results = collector.results

# => {
#      total_queries: 2,
#      crud_operations_by_table: {
#        users: { SELECT: 1, INSERT: 1 }
#      }
#    }
```

## How It Works

The gem subscribes to `ActiveSupport::Notifications` for SQL events and tracks:

1. **Total query count**: How many SQL queries were executed
2. **Operations by table**: Breakdown of INSERT, SELECT, UPDATE, DELETE per table
3. **Accurate row counts**: Uses Rails 7.2+ `payload[:row_count]` to correctly count affected rows in all operations, including bulk operations like `insert_all`

### Bulk Operations

Traditional query counters treat `insert_all` as a single operation:

```ruby
# Without activerecord-db-metrics
User.insert_all([{name: "A"}, {name: "B"}, {name: "C"}])
# => Counted as INSERT: 1 ❌
```

This gem correctly counts the actual rows affected:

```ruby
# With activerecord-db-metrics
User.insert_all([{name: "A"}, {name: "B"}, {name: "C"}])
# => Counted as INSERT: 3 ✅
```

## Requirements

- Ruby >= 2.7.0
- Rails >= 7.2
- ActiveRecord >= 7.2

This gem requires Rails 7.2+ to utilize the `row_count` field in `sql.active_record` notifications ([PR #50887](https://github.com/rails/rails/pull/50887)).

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
rake spec
```

To build the gem:

```bash
gem build activerecord-db-metrics.gemspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
