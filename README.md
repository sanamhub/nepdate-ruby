<p align="center">
  <img src="https://raw.githubusercontent.com/sanamhub/nepdate-ruby/main/docs/assets/nepdate-ruby-128.png" width="128" alt="NepDate for Ruby logo">
</p>

<h1 align="center">nepdate-ruby</h1>

<p align="center">
  <a href="https://github.com/sanamhub/nepdate-ruby/actions/workflows/ci.yml"><img src="https://github.com/sanamhub/nepdate-ruby/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://rubygems.org/gems/nepdate"><img src="https://img.shields.io/gem/v/nepdate?include_prereleases&label=nepdate&logo=rubygems&logoColor=white" alt="nepdate on RubyGems"></a>
  <a href="https://rubygems.org/gems/nepdate-patro"><img src="https://img.shields.io/gem/v/nepdate-patro?include_prereleases&label=nepdate-patro&logo=rubygems&logoColor=white" alt="nepdate-patro on RubyGems"></a>
  <img src="https://img.shields.io/badge/Ruby-3.4%2B-CC342D?logo=ruby&logoColor=white" alt="Ruby 3.4 or newer">
  <a href="https://github.com/sanamhub/nepdate-ruby/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT"></a>
</p>

Bikram Sambat (Nepali calendar) dates for Ruby: conversion to and from Gregorian, arithmetic with
an explicit overflow mode, formatting and parsing in English and Nepali, ranges and fiscal years.
Part of the NepDate family: the shared data and specification live in the hub
[`sanamhub/nepdate`](https://github.com/sanamhub/nepdate); the C# original is
[NepDate](https://github.com/RajuPrasai/NepDate) by Raju Prasai.

> **Status:** 1.0.0-rc.1, the release candidate for Ruby on RubyGems. The API is listed in
> [docs/API.md](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/API.md) and is stable from
> 1.0 (hub ADR-0009). Patro data (tithi, holidays, events) is informational, not an official
> calendar.

Two gems, released together with the same version and one tag:

- [`nepdate`](https://rubygems.org/gems/nepdate): dates, conversion, arithmetic, formatting,
  parsing, ranges and fiscal years. No runtime dependencies and no almanac data.
- [`nepdate-patro`](https://rubygems.org/gems/nepdate-patro): the patro (पात्रो, the Nepali
  almanac): tithi, public holidays and events from BS 2077-01-01 to 2084-08-20. It depends on
  `nepdate`.

Pure Ruby, Ruby 3.4 or newer, on Linux, macOS and Windows. Every clock function takes a zone or a
fixed offset, or a clock you inject, so it never reads a hidden local zone. The supported range is
BS 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15), with the same results as C# NepDate and
the other ports, checked against the shared vectors.

## Install

```sh
gem install nepdate -v 1.0.0.rc.1
gem install nepdate-patro -v 1.0.0.rc.1
```

In a Gemfile:

```text
gem "nepdate", "1.0.0.rc.1"
gem "nepdate-patro", "1.0.0.rc.1" # tithi, holidays and events
```

RubyGems spells this release candidate `1.0.0.rc.1`; the tag and the changelog keep the family
spelling `v1.0.0-rc.1`.

```ruby
require "nepdate"
require "nepdate/patro"
```

## Quick start

```ruby
date = NepDate::Date.from_bs(2081, 4, 15)
raise unless date.to_s == "2081/04/15"
raise unless date.to_date.iso8601 == "2024-07-30"
raise unless date.to_long_string(weekday: true) == "Tuesday, Shrawan 15, 2081"
raise unless NepDate::Date.parse("2081/04/15") == date
puts date.to_s
```

## Dates

A `NepDate::Date` is immutable and always a real day. The constructor validates the year first,
then the month, then the day, and raises a `NepDate::Error` with a `kind` symbol. There is no invalid
or default date.

```ruby
date = NepDate::Date.from_bs(2081, 4, 32)
raise unless date.year == 2081
raise unless date.month == 4
raise unless date.day == 32
raise unless date.weekday == NepDate::Weekday::FRIDAY
raise unless date.day_of_year == 126
raise unless date.month_length == 32
raise unless date.year_length == 366
raise unless NepDate::Date::MIN.to_s == "1901/01/01"
raise unless NepDate::Date::MAX.to_s == "2199/12/30"
puts date.month_enum.label
```

The month value replaces the C# month enum and the year length replaces `IsLeapYear()` (`D-12`).

```ruby
date = NepDate::Date.from_bs(2081, 4, 15)
raise unless date.month_enum == NepDate::Month::SHRAWAN
raise unless date.last_day_of_month.to_s == "2081/04/32"
raise unless date.to_a == [2081, 4, 15]
raise unless date.fiscal_year.label == "2081/82"
year, month, day = date
raise unless [year, month, day] == [2081, 4, 15]
puts date.month_enum.label
```

## Conversion and serialization

Convert a `::Date`, `DateTime` or `Time` by its date part; the time of day is discarded. The
canonical text form is `YYYY-MM-DD`, and the `YYYYMMDD` integer works both ways.

```ruby
date = NepDate::Date.from_date(::Date.new(2024, 7, 30))
raise unless date.to_s == "2081/04/15"
raise unless NepDate::Date.from_ymd(20_810_415) == date
raise unless date.to_ymd == 20_810_415
raise unless date.iso8601 == "2081-04-15"
raise unless date.to_json == '"2081-04-15"'
raise unless NepDate::Date.from_json(date.to_json) == date
puts date.to_json
```

Batch conversion keeps input order. A single bad item makes the whole call raise.

```ruby
date = NepDate::Date.from_date(::Date.new(2024, 7, 30))
raise unless NepDate::Date.from_gregorian_batch([::Date.new(2024, 7, 30)]) == [date]
raise unless NepDate::Date.parse_batch(["2081-04-15"]) == [::Date.new(2024, 7, 30)]
raise unless NepDate::Date.to_gregorian_batch([date]) == [::Date.new(2024, 7, 30)]
puts date.iso8601
```

## Arithmetic

Months are whole numbers. When the day does not exist in the target month, `:clamp` (the default)
uses the last day and `:spill` carries the extra days into the next month. A named `days_until` is
`other - self`; the `-` operator is `self - other`, the C# direction (`D-07`).

```ruby
date = NepDate::Date.from_bs(2081, 4, 32)
raise unless date.add_days(30).to_s == "2081/05/30"
raise unless date.add_months(2).to_s == "2081/06/30"
raise unless date.add_months(2, overflow: :spill).to_s == "2081/07/02"
raise unless date.add_years(1).to_s == "2082/04/31"
raise unless date.days_until(NepDate::Date.from_bs(2081, 5, 1)) == 1
raise unless (date - NepDate::Date.from_bs(2081, 4, 15)) == 17
raise unless date.diff(NepDate::Date.from_bs(2081, 5, 31)).days == 0
puts date.add_months(2).to_s
```

## Formatting

Short formats take an order, a separator, a padding flag and a language. The long form is
`[Weekday, ]Month day[, year]`. Nepali output uses Devanagari names and digits. Patterns accept
`yyyy`, `yy`, `MMMM`, `MMM`, `MM`, `M`, `dd`, `d`, a backslash escape and a quoted literal.

```ruby
date = NepDate::Date.from_bs(2081, 4, 15)
raise unless date.to_s == "2081/04/15"
raise unless date.to_short_string(order: :dmy, separator: :dash) == "15-04-2081"
raise unless date.to_short_string(lang: :ne) == "२०८१/०४/१५"
raise unless date.to_long_string == "Shrawan 15, 2081"
raise unless date.to_long_string(weekday: true, lang: :ne) == "मङ्गलवार, साउन १५, २०८१"
raise unless date.format("MMMM d, yyyy") == "Shrawan 15, 2081"
raise unless date.format("MMM yy") == "Shr 81"
puts date.to_unicode_string
```

## Parsing

The strict parser takes year, month and day in that order, with ASCII or Devanagari digits and the
separators `- / . _ \ space | ।`. The lenient parser accepts month names in English or Nepali, the
day before the year, and era markers such as `B.S.`. Both have non-throwing forms.

```ruby
raise unless NepDate::Date.parse("2081/04/15").to_s == "2081/04/15"
raise unless NepDate::Date.parse("२०८१/०४/१५").to_s == "2081/04/15"
raise unless NepDate::Date.parse_lenient("15 Shrawan 2081 B.S.").to_s == "2081/04/15"
raise unless NepDate::Date.try_parse("2081/13/01").nil?
raise unless NepDate::Date.try_parse_lenient("15 Foo 2081").nil?

begin
  NepDate::Date.parse("2081/13/01")
rescue NepDate::Error => error
  raise unless error.kind == :invalid_month
end
puts "parsing: ok"
```

A failure raises a `NepDate::Error`; `kind` says whether the character, the group count, the number
length, the date fields or the form was wrong.

## Ranges

A range is inclusive and always has at least one day. It includes `Enumerable`, has value equality
and a hash, and offers containment, overlap, adjacency, intersection, union, difference, month and
fiscal-quarter splits, an interval walk, working days and weekend days.

```ruby
range = NepDate::DateRange.new(
  NepDate::Date.from_bs(2081, 4, 10),
  NepDate::Date.from_bs(2081, 4, 20)
)
raise unless range.length == 11
raise unless range.to_s == "2081/04/10 - 2081/04/20"
raise unless range.include?(NepDate::Date.from_bs(2081, 4, 15))
raise unless range.overlaps?(NepDate::DateRange.for_month(2081, 4))
raise unless range.intersect(NepDate::DateRange.for_month(2081, 5)).nil?
raise unless range.split_by_month.length == 1
raise unless range.dates_with_interval(5).length == 3
raise unless range.working_days.length == 9
raise unless NepDate::DateRange.for_month(2081, 4).length == 32
raise unless NepDate::DateRange.for_year(2081).length == 366
puts range.to_s
```

## Fiscal year

A fiscal year starts on 1 Shrawan and ends on the last day of Ashad of the next BS year. Quarters
are Q1 Shrawan to Ashoj, Q2 Kartik to Poush, Q3 Magh to Chaitra and Q4 Baishakh to Ashad. A
`FiscalYear` value answers all of them, so there is no `yearOffset` argument.

```ruby
fiscal = NepDate::FiscalYear.containing(NepDate::Date.from_bs(2082, 2, 1))
raise unless fiscal.label == "2081/82"
raise unless fiscal.start.to_s == "2081/04/01"
raise unless fiscal.end.to_s == "2082/03/32"
raise unless fiscal.quarter_range(:q1).to_s == "2081/04/01 - 2081/06/30"
raise unless fiscal.quarter_range(:q4).to_s == "2082/01/01 - 2082/03/32"
puts fiscal.label
```

## Today

`today` reads the system clock unless you pass `clock:`. The zone defaults to `Asia/Kathmandu`;
`UTC`, `GMT`, a fixed offset such as `+05:45`, or a numeric offset in seconds are also accepted.
Nepal has no daylight saving time, so a fixed offset is complete. Use `from_date` when the date in
hand already has the zone you want.

```ruby
clock = -> { Time.utc(2024, 7, 30, 18, 30) }
raise unless NepDate::Date.today(clock: clock).to_s == "2081/04/16"
raise unless NepDate::Date.today(zone: "UTC", clock: clock).to_s == "2081/04/15"
raise unless NepDate::Date.from_bs(2081, 4, 16).today?(clock: clock)
raise unless NepDate::Date.from_bs(2081, 4, 14).yesterday?(zone: "UTC", clock: clock)
raise unless NepDate::Date.from_bs(2081, 4, 16).tomorrow?(zone: "UTC", clock: clock)
puts NepDate::Date.today(zone: "UTC", clock: clock)
```

## Patro: tithi, holidays and events

The core has no patro data. Add both gems. The patro compiles its tithi, public holiday and event
data into constant tables, so nothing is read or parsed at run time. `info` never fails: a day
without data, and any day outside the coverage, gets a nil tithi, a false holiday flag and no events.
The data covers BS 2077-01-01 to 2084-08-20.

```ruby
day = NepDate::Patro.info(NepDate::Date.from_bs(2081, 2, 15))
raise unless day.public_holiday?
raise unless day.tithi.nepali == "पञ्चमी"
raise unless day.tithi.english == "Panchami"
raise unless day.events_en == ["Republic Day"]
raise unless NepDate::Patro.coverage.start.to_s == "2077/01/01"
raise unless NepDate::Patro.public_holidays.length == 294
raise unless NepDate::Date.from_bs(2081, 1, 1).calendar_info.events_en.include?("New Year")
puts day.events_en.first
```

## Supported versions and platforms

- Ruby 3.4 or newer, tested on 3.4, the current stable release and `head` on Linux, macOS and
  Windows. Ruby 3.3 is not supported because its security support ends on 2027-03-31.
- Pure Ruby with no native extension and no runtime dependency. `nepdate-patro` depends only on
  `nepdate`.
- `nepdate` and `nepdate-patro` share one version and one release tag.
- There is no time zone database: a clock function takes a fixed offset, a numeric offset or a clock
  you inject. `Asia/Kathmandu`, `Asia/Katmandu` and `NPT` are aliases for `+05:45`.

## Data and correctness

The calendar data is the same data every NepDate port uses, a read-only copy of the hub's
`shared/data/`. The test suite loads all 19 shared vector files, 29,215 rows, including the golden
output of C# NepDate 2.0.7, the C# test catalogue and every `ERR` row, and checks the properties the
specification states.
Dates and behaviour come from `shared/spec`, not from another port's README. Month lengths beyond
the officially published calendar are projections inherited from C# NepDate.

The API implements 108 of the 124 rows in the hub's `spec/API.md`; the other 16 are removed by the
documented decisions in [`spec/PARITY.md`](https://github.com/sanamhub/nepdate/blob/main/spec/PARITY.md)
and are listed in [docs/API.md](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/API.md).

## Documentation

| Page | What it covers |
|---|---|
| [API](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/API.md) | Every public type and member, with an example |
| [Benchmarks](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/benchmarks.md) | B1 to B8 against the C# baseline and the Ruby field |
| [Competitors](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/competitors.md) | The RubyGems candidates considered for the benchmark |
| [ADRs](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/adr/README.md) | Why the design is what it is |
| [Release](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/runbooks/release.md) | Tagging, publishing and the post-publish check |
| [Changelog](https://github.com/sanamhub/nepdate-ruby/blob/main/CHANGELOG.md) | What changed in each version |
| [Contributing](https://github.com/sanamhub/nepdate-ruby/blob/main/CONTRIBUTING.md) | Setup, gates and commits |
| [Security](https://github.com/sanamhub/nepdate-ruby/blob/main/SECURITY.md) | Reporting a vulnerability |
| [Data error form](https://github.com/sanamhub/nepdate/issues/new/choose) | A wrong date, holiday or tithi, reported in the hub |
| [Spec](https://github.com/sanamhub/nepdate/tree/main/spec) | Behaviour and vectors, in the hub |
| [Other languages](https://github.com/sanamhub/nepdate#packages) | The same library in the other NepDate ports |

## Benchmarks

`bench/` measures B1 to B8 of the shared benchmark specification against the C# NepDate baseline
and the Python port, the closest same-kind runtime. No RubyGems library passes the maturity and
usage bar, so there is no Ruby competitor column; the
evidence is in [docs/competitors.md](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/competitors.md).
The machine, the method and the current numbers, including the Python reference and the YJIT row,
are in [docs/benchmarks.md](https://github.com/sanamhub/nepdate-ruby/blob/main/docs/benchmarks.md).

## Contributing

Bug reports, fixes and documentation improvements are welcome; open an issue before a new feature
or an API change. `bundle exec rake ci` runs every gate and must pass before a pull request. The
details are in [CONTRIBUTING.md](https://github.com/sanamhub/nepdate-ruby/blob/main/CONTRIBUTING.md).

## Credit

NepDate for Ruby is a port of [NepDate](https://github.com/RajuPrasai/NepDate), the C# library by
Raju Prasai and contributors. The data and the behaviour follow it with the deliberate, documented
deviations in the hub's
[`spec/PARITY.md`](https://github.com/sanamhub/nepdate/blob/main/spec/PARITY.md).

## License

MIT ([LICENSE](https://github.com/sanamhub/nepdate-ruby/blob/main/LICENSE)). Calendar and patro data
from NepDate by Raju Prasai and contributors, MIT
([NOTICE](https://github.com/sanamhub/nepdate-ruby/blob/main/NOTICE)). Not affiliated with the
Government of Nepal.
