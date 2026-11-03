# Benchmarks

B1 to B8 of [`spec/BENCHMARK.md`](https://github.com/sanamhub/nepdate/blob/main/spec/BENCHMARK.md)
for `nepdate` 1.0.0-rc.1. The run is **preliminary**: the machine was not idle. It was measured on
the reference machine with the owner's normal desktop applications open, and the whole-machine CPU
load before the run averaged **17.0%** over 30 seconds (min 2%, max 46%); after the run it averaged
**19.1%** (min 1%, max 66%). A quiet rerun is required before 1.0.

## Machine and versions

| Item | Value |
|---|---|
| CPU | 12th Gen Intel Core i5-12500H (4 performance + 8 efficiency cores, 16 threads, base 3.1 GHz) |
| RAM | 31.7 GB |
| OS | Windows 11 Home 10.0.26300 |
| Power plan | Ultimate Performance, on AC |
| Affinity | logical CPU 2 (mask `0x4`) |
| Ruby | 3.4.12 (2026-10-23 revision 366f5fdc00) +PRISM, x64-mingw-ucrt, RubyInstaller portable 7z |
| Harness | `bench/bench.rb`, monotonic clock, 10 samples per operation |
| Date of run | 2026-11-03 |
| C# baseline | NepDate 2.0.7, .NET 10.0.14, from the hub's `docs/benchmarks/dotnet.md` |

No competitor column: no RubyGems library passes the section 7 rule. The evidence is in
[`docs/competitors.md`](competitors.md).

## Command

From the repository root:

```text
start "" /affinity 4 /wait /b ruby -Ipackages/nepdate/lib -Ipackages/nepdate-patro/lib bench/bench.rb
```

The harness uses the 64 dates of BENCHMARK.md section 2, one pass over all 64 is one iteration, and
B8 treats one month grid as one operation. Warm-up is one pass followed by a pass of at least 0.15 s.
It reports the mean and sample standard deviation of 10 timed samples. The raw result is
[`bench/results/2026-11-03.json`](https://github.com/sanamhub/nepdate-ruby/blob/main/bench/results/2026-11-03.json).

## Results

Time is nanoseconds per single operation. Bytes per operation are not measured: Ruby has no reliable
per-operation byte allocator, which BENCHMARK.md allows to be reported as not measured. The C# column
is the same operation on the same 64 inputs, measured on the same machine.

| ID | Operation | Ruby ns/op | std dev ns | C# .NET 10 ns/op | Ruby / C# | C# bytes/op |
|---|---|---:|---:|---:|---:|---:|
| B1 | BS to AD | 506.4 | 12.6 | 13.50 | 37.5x | 0 |
| B2 | AD to BS | 2,359.4 | 95.0 | 20.10 | 117.4x | 0 |
| B3 | add 1000 days | 2,025.4 | 413.7 | 19.05 | 106.3x | 0 |
| B4 | add 13 months, Clamp | 1,478.4 | 31.3 | 20.19 | 73.2x | 0 |
| B5 | long format, Nepali, weekday | 3,560.0 | 585.1 | 150.41 | 23.7x | 435 |
| B6 | strict parse `YYYY/MM/DD` | 3,199.6 | 75.4 | 22.42 | 142.7x | 0 |
| B7 | patro info | 2,838.5 | 90.9 | 48.21 | 58.9x | 51 |
| B8 | patro month grid | 151,507.2 | 7,634.9 | 3,112.76 | 48.7x | 1,429 |

## Reading the numbers

The Ruby port is a pure-Ruby value library with no C extension and no JIT. Every conversion allocates
a frozen `NepDate::Date`; every formatting call allocates the intermediate strings; every patro
lookup allocates a `CalendarInfo`, a tithi and its events. C# does the same work with a struct, a
stack buffer and a JIT, so the gap is in the C# favour on every row. The fastest Ruby row is BS to
AD, where the arithmetic and the `Date` conversion dominate and the smaller number of objects keeps
the cost under a microsecond.

The benchmark does not cache results: B7 and B8 intentionally pay for the objects a caller receives,
so the numbers are not flattered by a memoization layer. A C extension is not in this release. It
would be considered only if a later benchmark shows pure Ruby far behind and a new ADR measures the
gain. The quiet rerun before 1.0 replaces this table; these numbers are not a target verdict.

The family reference is C#, not a Ruby library. BENCHMARK.md section 6 has no Ruby row and no Ruby
competitor passed section 7, so there is no same-language reference on which this port is "slower on
most rows". `docs/competitors.md` records that case.
