# Benchmarks

B1 to B8 of [`spec/BENCHMARK.md`](https://github.com/sanamhub/nepdate/blob/main/spec/BENCHMARK.md)
for `nepdate` 1.0.0-rc.1. The run is **quiet**: the whole-machine CPU load was sampled for 30
seconds before each session and every second during it, and the machine was otherwise idle.

The closest same-kind reference is the Python port. Both are interpreted, dynamically typed
runtimes with the same table-driven design, so Python is measured in the same session and every
Ruby row is compared with it. C# NepDate remains the family baseline. The Python figures are the
Python port's own idle run of the same day for Windows, and a Python run in WSL straight after the
Ruby runs for Linux.

## Machine and versions

| Item | Value |
|---|---|
| CPU | 12th Gen Intel Core i5-12500H (4 performance + 8 efficiency cores, 16 threads, base 3.1 GHz) |
| RAM | 31.7 GB |
| OS | Windows 11 Home 10.0.26300, with WSL 2 Ubuntu 26.04.1 for the YJIT row |
| Power plan | Ultimate Performance, on AC |
| Affinity | logical CPU 2 (mask `0x4`) |
| Ruby, Windows | 3.4.12 (2026-10-23 revision 366f5fdc00) +PRISM, x64-mingw-ucrt, RubyInstaller portable 7z. This build has no YJIT support. |
| Ruby, Linux | 3.4.12 (2026-10-23 revision 366f5fdc00) +YJIT +PRISM, x86_64-linux, built from the ruby-lang tarball with rustc 1.99.1 |
| Python, Windows | 3.12.13 (MSC v.1944 64 bit), pyperf 2.10.0 |
| Python, Linux | 3.12.16 (Clang 23.1.3), pyperf 2.10.0 |
| Harness | `bench/bench.rb`, monotonic clock, 10 samples per operation, one pass over the 64 inputs per iteration |
| Date of run | 2026-11-16 |
| C# baseline | NepDate 2.0.7, .NET 10.0.15, from the hub's `docs/benchmarks/dotnet.md` |

The Windows Ruby session had an idle gate of **5.1%** average (peak 14.5%) over 30 one-second samples,
and **9.7%** average (peak 14.5%) during the run, over 23 samples. The Linux Ruby session had a gate
of **5.9%** average (peak 16.2%), and **12.1%** average during the run; a burst of up to **36.1%**
fell in the first five seconds, while WSL and the first benchmark were starting. The Linux Python run
had a gate of **5.3%** and **10.1%** average during the run, with the same startup burst of up to
**36.8%** in its first three seconds, before the first benchmark started. The load files are
`bench/results/2026-11-16-*-cpu-samples.txt`. Python's own `loaded` flag is false on every row used.

## Commands

From the repository root on Windows:

```text
start "" /affinity 4 /wait /b ruby -Ipackages/nepdate/lib -Ipackages/nepdate-patro/lib bench/bench.rb --label windows
```

From the repository root in WSL, with the source-built Ruby:

```text
taskset -c 2 ruby -Ipackages/nepdate/lib -Ipackages/nepdate-patro/lib bench/bench.rb --label linux
taskset -c 2 ruby --yjit -Ipackages/nepdate/lib -Ipackages/nepdate-patro/lib bench/bench.rb --label linux-yjit
```

Python was run one operation per process, as its harness requires:

```text
uv run --group bench python benchmarks/bench.py --only b1 -o b1.json --rigorous --quiet
```

The same command was run for `b2` through `b8`. The Ruby harness uses the 64 dates of BENCHMARK.md
section 2, one pass over all 64 is one iteration, and B8 treats one month grid as one operation.
Warm-up is one pass followed by a pass of at least 0.15 s. It reports the mean and sample standard
deviation of 10 timed samples. Python used pyperf's `--rigorous` mode and 120 measured values per
row.

## Windows result

Time is nanoseconds per single operation, lower is better. `Ruby before` is commit `2cbefdd` with
the same harness, so only the library code differs; it and `Ruby 2026-11-04` are the earlier runs,
kept for the direction of the change. Bytes per operation are not measured: Ruby has
no reliable per-operation byte allocator, which BENCHMARK.md allows to be reported as not measured.
The C# column is the same operation on the same 64 inputs, measured on the same machine.

| ID | Operation | Python ns/op | Ruby before ns/op | Ruby 2026-11-04 ns/op | Ruby now ns/op | Ruby now / Python | C# .NET 10 ns/op |
|---|---|---:|---:|---:|---:|---:|---:|
| B1 | BS to AD | 612.8 | 498.8 | 575.2 | 462.7 | 0.76x | 13.27 |
| B2 | AD to BS | 518.9 | 2,380.9 | 531.8 | 430.4 | 0.83x | 18.70 |
| B3 | add 1000 days | 474.3 | 2,365.8 | 630.0 | 458.2 | 0.97x | 20.06 |
| B4 | add 13 months, Clamp | 431.3 | 1,612.4 | 478.1 | 438.1 | 1.02x | 19.30 |
| B5 | long format, Nepali, weekday | 433.4 | 3,337.8 | 506.1 | 475.8 | 1.10x | 139.04 |
| B6 | strict parse `YYYY/MM/DD` | 1,157.1 | 3,446.3 | 1,430.8 | 1,211.3 | 1.05x | 21.13 |
| B7 | patro info | 118.9 | 2,798.4 | 123.0 | 108.1 | 0.91x | 48.63 |
| B8 | patro month grid | 15,840.1 | 144,478.6 | 17,828.8 | 16,324.6 | 1.03x | 3,274.50 |

Raw files:
[2026-11-16-windows.json](https://github.com/sanamhub/nepdate-ruby/blob/main/bench/results/2026-11-16-windows.json),
[2026-11-16-python-windows.json](https://github.com/sanamhub/nepdate-ruby/blob/main/bench/results/2026-11-16-python-windows.json),
and the earlier
[2026-11-04.json](https://github.com/sanamhub/nepdate-ruby/blob/main/bench/results/2026-11-04.json) and
[2026-11-04-windows-before.json](https://github.com/sanamhub/nepdate-ruby/blob/main/bench/results/2026-11-04-windows-before.json).

## Linux and YJIT

The Windows Ruby has no YJIT support, so the YJIT row was measured on WSL 2 on the same machine,
with Python Linux in the same session. The site uses the Windows row, which is the default
interpreter setting; the YJIT row is evidence for a deployment that enables it.

| ID | Operation | Python ns/op | Ruby ns/op | Ruby `--yjit` ns/op | Ruby / Python | YJIT / Python |
|---|---|---:|---:|---:|---:|---:|
| B1 | BS to AD | 440.5 | 481.5 | 240.9 | 1.09x | 0.55x |
| B2 | AD to BS | 416.5 | 445.1 | 152.3 | 1.07x | 0.37x |
| B3 | add 1000 days | 373.2 | 458.6 | 176.1 | 1.23x | 0.47x |
| B4 | add 13 months, Clamp | 329.4 | 422.5 | 96.4 | 1.28x | 0.29x |
| B5 | long format, Nepali, weekday | 307.5 | 396.1 | 177.5 | 1.29x | 0.58x |
| B6 | strict parse `YYYY/MM/DD` | 851.4 | 1,230.3 | 537.4 | 1.45x | 0.63x |
| B7 | patro info | 91.7 | 114.4 | 19.1 | 1.25x | 0.21x |
| B8 | patro month grid | 12,670.9 | 15,431.4 | 6,047.1 | 1.22x | 0.48x |

Raw files:
[2026-11-16-linux.json](https://github.com/sanamhub/nepdate-ruby/blob/main/bench/results/2026-11-16-linux.json),
[2026-11-16-linux-yjit.json](https://github.com/sanamhub/nepdate-ruby/blob/main/bench/results/2026-11-16-linux-yjit.json)
and
[2026-11-16-python-linux.json](https://github.com/sanamhub/nepdate-ruby/blob/main/bench/results/2026-11-16-python-linux.json).

## The 1.5x target

BENCHMARK section 6 asks for every operation within 1.5 times the Python port, without YJIT. Every
row is within 1.5 times Python in its own table. The closest are B6 on Linux at 1.45 times, B5 on
Linux at 1.29 times and B4 on Linux at 1.28 times. No row needs a measured exception.

The before column shows that the gap was in the algorithms, not in Ruby. B1 was already close to
Python, while B2, B3, B4, B5, B6, B7 and B8 each paid for work the Python port does once. The
changes are:

- **Conversion and day arithmetic.** The generated table now holds the start serial of every month
  and a 32-day bucket index. A serial is found with one array read and at most two comparisons,
  instead of a binary search over years and a scan over months. `Date.from_date` uses `::Date#jd`
  directly. `add_months` uses the same month index and start serial, with no scan.
- **Formatting.** The digit strings for years, months, days and two-digit years are built once and
  frozen at load. The long Nepali form reads them directly and appends to one string, with no
  per-call `to_s`, `rjust` or `tr`.
- **Parsing.** The common ten-byte ASCII form is read with `getbyte` and integer arithmetic before
  the general UTF-8 scanner runs. The scanner still handles Devanagari digits, the danda and every
  malformed input.
- **Patro.** One immutable `CalendarInfo` is built per coverage day at load, sharing the tithi and
  event objects, and `info` is an array read by serial. This is the table itself, not a memoization
  keyed by input: the values are immutable, so returning the shared value is the same as returning
  a new equal one.
- **Range iteration.** `DateRange#each` walks the serial range and builds each date directly,
  instead of calling `succ` and re-checking the day offset per day.

## Reading the numbers

The Ruby port is a pure-Ruby value library with no C extension. Every conversion still allocates a
frozen `NepDate::Date`; formatting still allocates the result string; B7 and B8 still walk every
day of every month grid. C# does the same work with a struct and a JIT, so the gap remains in the C#
favour on every row; the Ruby numbers are not a claim that Ruby matches a compiled runtime.

There is no Ruby competitor column: no RubyGems library passes the section 7 usage floor, and the
five candidates are in [docs/competitors.md](competitors.md). Python is a same-kind reference, not
a RubyGems competitor, and it is not ranked in that table. A C extension is not in this release; it
would be considered only if a later benchmark shows pure Ruby far behind and a new ADR measures the
gain.
