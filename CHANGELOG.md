# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An Amazon Aurora global cluster, for Aurora PostgreSQL or Aurora MySQL, new and empty or made from an existing Aurora cluster.
- Secure defaults: storage encrypted and deletion protection on.
- Engine upgrades in place through `engine_version`, and the RDS Extended Support setting.
- Checks at plan time for the identifier, the engine, the source cluster ARN, and inputs that cannot be combined.
- `Scope`, `Purpose` and `Environment` tags from the `details` input.
- `region`, to manage the global cluster from a Region other than the provider's.
- A `metadata` output with the global cluster's identifier, ARN, global writer endpoint and settings.
- Offline tests, and examples for an empty global cluster, a two-Region global database, and a global cluster made from an existing cluster.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-rds_aurora_global_cluster/releases/tag/v1.0.0
