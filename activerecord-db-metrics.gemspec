# frozen_string_literal: true

require_relative 'lib/activerecord/db/metrics/version'

Gem::Specification.new do |spec|
  spec.name = 'activerecord-db-metrics'
  spec.version = ActiveRecord::Db::Metrics::VERSION
  spec.authors = ['Masato Kato']
  spec.email = ['masatokato0000@gmail.com']

  spec.summary = 'Track and analyze ActiveRecord database operations per request'
  spec.description = 'A lightweight gem to monitor and measure database queries in Rails applications, providing detailed metrics on CRUD operations per table including support for bulk operations like insert_all.'
  spec.homepage = 'https://github.com/00Masato/activerecord-db-metrics'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.4.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['lib/**/*', 'README.md', 'LICENSE.txt', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  # Dependencies
  # Requires Rails 7.2+ for sql.active_record payload[:row_count] support
  spec.add_dependency 'activerecord', '>= 7.2'
  spec.add_dependency 'activesupport', '>= 7.2'
end
