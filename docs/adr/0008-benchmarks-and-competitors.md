# ADR-0008: Benchmark-ips shape, manual timing and the RubyGems rule

- **Status:** accepted
- **Date:** 2026-11-03

## Context

The shared benchmark protocol fixes B1 to B8, the 64 dates and the reference machine. Ruby has
`benchmark-ips`, but a B8 month grid takes milliseconds and `benchmark-ips` reports iterations per
second without the per-input split the protocol asks for. Ruby also has no standard per-operation
byte allocator. The competitor section has no Ruby row.

## Decision

1. `bench/bench.rb` uses a monotonic clock directly: a warm-up pass, then 10 timed samples per
   operation, each over all 64 inputs, reported as nanoseconds per single operation. B8 is one
   month grid per input.
2. The harness is pinned to logical CPU 2 with `start /affinity 4 /wait /b`, the same core as the
   spec. The machine load is sampled for 30 seconds before and after and recorded in
   `docs/benchmarks.md`; a run is preliminary unless both averages are under 15%.
3. Bytes per operation are `not measured`, because Ruby has no reliable allocator counter. The
   shared spec allows this for a dynamic language.
4. The RubyGems competitor measure is 10,000 total downloads, the Packagist analogue, because the
   registry API exposes total downloads and no monthly figure. The candidates and verdicts are in
   `docs/competitors.md`.
5. No candidate passes, so there is no competitor column. The C# .NET 10 column from the hub is the
   family reference. Ruby has no same-language sibling, so no sibling column is invented.
6. The numbers in this release are preliminary. A quiet rerun before 1.0 replaces them; the current
   run's CPU load is recorded rather than hidden.

## Consequences

- A future quiet run changes only `bench/results/` and `docs/benchmarks.md`; the harness does not
  need a new dependency.
- A benchmark table with no competitor is the honest result of the registry data, not an omission.
