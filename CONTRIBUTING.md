# Contributing

Thanks for helping. This repository holds the Ruby `nepdate` gem and the `nepdate-patro` gem.

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Report security problems as
described in [SECURITY.md](SECURITY.md), not in a public issue.

## Before you start

- Open an issue before a new feature or an API change, so we can agree on it first.
- Data and spec problems (a wrong date, holiday or tithi) belong in the hub,
  [`sanamhub/nepdate`](https://github.com/sanamhub/nepdate). `shared/` here is a read-only copy.

## Setup

- Ruby 3.4 or newer. On Windows, use the portable RubyInstaller archive; no Devkit is needed for
  the gems themselves, only for native development tools.
- `bundle install` installs the pinned development gems from the committed `Gemfile.lock`.
- The gems live in `packages/nepdate` and `packages/nepdate-patro`. The root `Gemfile` resolves both
  from those paths, so no `gem install` of this repository is needed.

## Making a change

1. Run `bundle exec rake ci` before you open a pull request. It must pass.
2. One change per pull request.
3. Add tests for every behaviour change; prefer a vector row in `shared/spec/vectors` over a
   hand-written case when one already covers it.
4. Add a changelog line for anything a user would notice.
5. Write an ADR in `docs/adr/` for a significant decision.
6. Use [Conventional Commits](https://www.conventionalcommits.org/), for example
   `feat(nepdate): add serial conversion`.
7. Commit messages and docs: imperative summary, lower case, no trailing period; the body says why,
   not what. Docs are plain prose without em dashes.

## Documentation

`README.md` and `docs/API.md` are executable. `bundle exec ruby scripts/check_examples.rb` runs every
fenced Ruby sample in a fresh process, and `rake ci` runs it, so a doc example cannot drift from the
code. Write `not measured` rather than guessing a benchmark figure.

## Benchmarks

`ruby bench/bench.rb` is the harness of `shared/spec/BENCHMARK.md`: B1 to B8 over the shared 64
dates. Change a number in `docs/benchmarks.md` only together with a run, and say on which machine it
was measured. A run is preliminary unless the machine was idle, CPU under 15% for 30 seconds, before
and after.

## Generated files

`packages/nepdate/lib/nepdate/calendar_table.rb` and
`packages/nepdate-patro/lib/nepdate/patro/table.rb` are generated from `shared/data/`. Change the
generator and run `bundle exec rake generate`. Don't edit the generated files by hand; CI runs
`bundle exec rake generate:check` and fails on drift.

## RBS

Every public method has a signature under `packages/*/sig/`. `bundle exec rake rbs` validates them
and runs `test/rbs/smoke.rb` through `rbs test`, which checks the signatures at run time. When you
add or rename a public method, change the signature in the same pull request.
