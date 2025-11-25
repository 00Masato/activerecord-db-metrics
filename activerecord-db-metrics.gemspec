# frozen_string_literal: true

require_relative "lib/activerecord/db/metrics/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-db-metrics"
  spec.version = ActiveRecord::Db::Metrics::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your.email@example.com"]

  spec.summary = "Track and analyze ActiveRecord database operations per request"
  spec.description = "A lightweight gem to monitor and measure database queries in Rails applications, providing detailed metrics on CRUD operations per table including support for bulk operations like insert_all."
  spec.homepage = "https://github.com/yourusername/activerecord-db-metrics"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["lib/**/*", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "activerecord", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
