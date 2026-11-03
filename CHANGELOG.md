# Changelog

All notable changes are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows
[Semantic Versioning](https://semver.org/). Every NepDate SDK shares one `MAJOR.MINOR` line, so this
repository joins at `1.0.0-rc.1` with the other ports
([hub ADR-0007](https://github.com/sanamhub/nepdate/blob/main/docs/adr/0007-one-version-line-for-every-sdk.md)).

## [Unreleased]

### Added

- The `nepdate` gem: Bikram Sambat dates from 1901-01-01 to 2199-12-30 with conversion to and from
  `Date`, `DateTime` and `Time`, the `YYYYMMDD` integer form, arithmetic with clamp and spill, the
  calendar breakdown between two dates, fiscal years and quarters, English and Nepali formatting
  with patterns, strict and lenient parsing, inclusive ranges with their set operations, ordered
  batch conversion, and the canonical JSON string.
- The `nepdate-patro` gem: tithi, public holidays and events for 2077-01-01 to 2084-08-20.
- Both gems are pure Ruby with no runtime dependency other than `nepdate-patro` on `nepdate`, and
  need Ruby 3.4 or newer.
- Calendar and patro tables generated from the shared data by `scripts/generate_*.rb`, a `--check`
  mode that fails on drift, and a check of the patro counts against the hub's summary.
- Tests for every shared vector file, every row of the C# test catalogue that applies, and the
  properties that hold for all 109212 supported days.
- One CI command, `bundle exec rake ci`, that runs the generator check, Standard, RBS validation and
  the runtime signature smoke test, YARD, the executable README and API examples, both test suites,
  the 90% line and branch coverage gate, and the release check.
- RBS signatures for the whole public API, ten architecture decisions, a release runbook, and a
  README and API reference whose Ruby samples run and are checked in CI.
- A benchmark of B1 to B8 against the C# baseline, with the RubyGems evidence in
  `docs/competitors.md`.
- CI on Linux, macOS and Windows over Ruby 3.4, the current stable release and `head`, the hub's
  shared-check, CodeQL for Ruby and Actions, Scorecard, dependency review, and the release and
  verify-published workflows.
