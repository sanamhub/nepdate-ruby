# Architecture decisions

| ADR | Decision |
|---|---|
| [0001](0001-layout-toolchain-and-shared-data.md) | One repository, two gems under `packages/`, pure Ruby 3.4+, vendored `shared/` |
| [0002](0002-value-type-and-generated-tables.md) | An immutable date with a serial day and generated calendar tables |
| [0003](0003-api-errors-and-the-clock.md) | Ruby names, one error hierarchy and an explicit clock or offset |
| [0004](0004-tests-and-quality-gates.md) | Minitest, SimpleCov 90% line and branch, Standard, RBS and YARD |
| [0005](0005-patro-as-a-second-gem.md) | The patro is a second gem with generated tables |
| [0006](0006-serialization.md) | One canonical text form and the native JSON hook |
| [0007](0007-release-and-rubygems.md) | One tag, two gems and RubyGems trusted publishing |
| [0008](0008-benchmarks-and-competitors.md) | B1 to B8 timing, the RubyGems usage rule and no selected competitor |
| [0009](0009-ruby-version-floor.md) | Ruby 3.4 is the floor |
| [0010](0010-mutation-testing.md) | No mutation gate because the Ruby tool's licence is not free for this project |
