# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-04-09

### Added
- Sidekiq server middleware (`ActiveRecord::Db::Metrics::SidekiqMiddleware`) for per-job DB metrics

## [0.1.0] - 2025-12-07

### Added
- Initial release
- Track database queries per request
- Breakdown by table and CRUD operation type
- Support for bulk operations (insert_all, upsert_all)
- Controller helper for easy integration
- Manual collector for custom usage
