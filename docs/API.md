# API

The public API of `nepdate` 1.0.0-rc.1 and `nepdate-patro` 1.0.0-rc.1. The inventory is the hub's
[`spec/API.md`](https://github.com/sanamhub/nepdate/blob/main/spec/API.md), where the C# column is
the reference. Every row is listed here with its Ruby spelling; the first column is the C# member,
not a row number.

A Ruby date is `NepDate::Date`, a value held as the BS year, month, day and a serial day number. It
is immutable and always a real day. Errors inherit `NepDate::Error`; `#kind` is a symbol from
`NepDate::ErrorKind`. There is no default or zero date (D-01), so no API returns an invalid one.

## Dates, identity and comparison

| C# signature | Ruby | Example or note |
|---|---|---|
| `NepaliDate(int yearBs, int monthBs, int dayBs)` | `NepDate::Date.new(year, month, day)`, `.from_bs` | `NepDate::Date.from_bs(2081, 4, 15)` |
| `NepaliDate(string rawNepaliDate)` | `.parse(text)` | `NepDate::Date.parse("2081-04-15")` |
| `NepaliDate(string rawNepaliDate, bool autoAdjust, bool monthInMiddle = true)` | not ported (D-05, D-06) | Use `.parse` or `.parse_lenient` |
| `NepaliDate(DateTime engDate)` | `.from_date(::Date)`, `.from_time(::Time)`, `.from_gregorian(y, m, d)` | `.from_date(::Date.new(2024, 7, 30))` |
| `bool IsDefault { get; }` | not ported (D-01) | Invalid dates cannot exist |
| `int Year { get; }` | `#year` | `date.year` |
| `int Month { get; }` | `#month`, `#month_enum` | `date.month` is 4; `date.month_enum` is `Month::SHRAWAN` |
| `int Day { get; }` | `#day` | `date.day` |
| `DateTime EnglishDate { get; }` | `#to_date`, `#to_datetime`, `#to_time` | `date.to_date` is `2024-07-30` |
| `DayOfWeek DayOfWeek { get; }` | `#weekday` | `date.weekday.label` is `"Tuesday"` |
| `int DayOfYear { get; }` | `#day_of_year` | `date.day_of_year` is 109 |
| `int MonthEndDay { get; }` | `#month_length`, `#month_end_day` | `date.month_length` is 32 |
| `NepaliMonths MonthName { get; }` | `#month_enum`, `#month_name` | `date.month_enum.label` is `"Shrawan"` |
| `static NepaliDate Today { get; }` | `.today(zone:, clock:)` | `Date.today(zone: "+05:45", clock: -> { Time.now })` |
| `static NepaliDate Now { get; }` | `.today` | A date has no time of day |
| `static readonly NepaliDate MinValue` | `Date::MIN` | `Date::MIN.iso8601` is `"1901-01-01"` |
| `static readonly NepaliDate MaxValue` | `Date::MAX` | `Date::MAX.iso8601` is `"2199-12-30"` |
| `NepaliDate MonthEndDate()` | `#last_day_of_month`, `#month_end_date` | `date.last_day_of_month.iso8601` is `"2081-04-32"` |
| `void Deconstruct(out int year, out int month, out int day)` | `#to_a`, `#to_h`, `#deconstruct`, `#deconstruct_keys` | `year, month, day = date` |
| `bool IsLeapYear()` | `#year_length` (D-12) | `date.year_length` is 366 |
| `bool IsToday()` | `#today?(zone:, clock:)` | `date.today?(zone: "UTC", clock: -> { Time.now })` |
| `bool IsYesterday()` | `#yesterday?(zone:, clock:)` | `date.yesterday?(zone: "UTC")` |
| `bool IsTomorrow()` | `#tomorrow?(zone:, clock:)` | `date.tomorrow?(zone: "UTC")` |
| `int CompareTo(NepaliDate obj)` | `#compare_to`, `#<=>` | `early <=> late` is -1 |
| `int CompareTo(object obj)` | not ported (typed comparison) | A non-date returns nil from `<=>` |
| `bool Equals(NepaliDate other)` | `#==`, `#eql?` | `date == same` |
| `override bool Equals(object obj)` | `#==` | A foreign value is false |
| `override int GetHashCode()` | `#hash` | Equal dates hash equally |
| `static bool operator ==(NepaliDate, NepaliDate)` | `==` | |
| `static bool operator !=(NepaliDate, NepaliDate)` | `!=` | |
| `static bool operator <(NepaliDate, NepaliDate)` | `<` | |
| `static bool operator <=(NepaliDate, NepaliDate)` | `<=` | |
| `static bool operator >(NepaliDate, NepaliDate)` | `>` | |
| `static bool operator >=(NepaliDate, NepaliDate)` | `>=` | |

```ruby
date = NepDate::Date.from_bs(2081, 4, 15)
raise unless date == NepDate::Date.parse("2081-04-15")
raise unless date.to_date.iso8601 == "2024-07-30"
raise unless date.day_of_year == 109
raise unless date.weekday.label == "Tuesday"
raise unless date.year_length == 366
raise unless date.last_day_of_month.iso8601 == "2081-04-32"
raise unless NepDate::Date::MIN.iso8601 == "1901-01-01"
raise unless NepDate::Date::MAX.iso8601 == "2199-12-30"
raise unless date.today?(zone: "UTC", clock: -> { Time.utc(2024, 7, 30, 12) })
puts "dates: ok"
```

## Conversion and serialization

| C# signature | Ruby | Example or note |
|---|---|---|
| `static NepaliDate ToNepaliDate(this DateTime englishDate)` | `.from_date`, `.from_time`, `.from_gregorian` | `.from_date(::Date.new(2024, 7, 30))` |
| `static NepaliDate ToNepaliDate(this string input)` | `.parse_lenient` | `.parse_lenient("15 Shrawan 2081")` |
| `static bool TryToNepaliDate(this string input, out NepaliDate result)` | `.try_parse_lenient` | `.try_parse_lenient("not a date")` is nil |
| `ToNepaliDates(IEnumerable<DateTime> engDates, bool useParallel = true)` | `.from_gregorian_batch(enum)` | `.from_gregorian_batch([::Date.new(2024, 7, 30)])` |
| `ToEnglishDates(IEnumerable<string> nepDates, bool useParallel = true)` | `.parse_batch(enum)` | `.parse_batch(["2081-04-15"])` |
| `ToEnglishDates(IEnumerable<NepaliDate> nepDates, bool useParallel = true)` | `.to_gregorian_batch(enum)` | `.to_gregorian_batch([date])` |
| `BatchProcessToNepaliDates(IEnumerable<DateTime>, int batchSize = 1000)` | `.from_gregorian_batch` | One ordered batch function |
| `BatchProcessToEnglishDates(IEnumerable<NepaliDate>, int batchSize = 1000)` | `.to_gregorian_batch` | One ordered batch function |
| `sealed class NepaliDateTypeConverter : TypeConverter` | `.from_ymd(int)`, `#to_ymd` (D-11) | No converter type |
| `class NepaliDateJsonConverter : JsonConverter<NepaliDate>` | `#to_json`, `.from_json` (D-11) | The canonical text is `"YYYY-MM-DD"` |
| `class NepaliDateObjectJsonConverter` | not ported (D-11) | No object form |
| `class NewtonsoftJsonConverters.NepaliDateJsonConverter` | not ported (D-11) | Native JSON hook only |
| `class NewtonsoftJsonConverters.NepaliDateObjectJsonConverter` | not ported (D-11) | No object form |
| `class NepaliDateXmlSerializer : IXmlSerializable` | not ported (D-11) | No XML adapter |
| `ConfigureForNepaliDate(this JsonSerializerOptions, bool useObjectFormat = false)` | not ported (D-11) | Ruby's JSON hook needs no options |
| `ConfigureForNepaliDate(this JsonSerializerSettings, bool useObjectFormat = false)` | not ported (D-11) | Ruby's JSON hook needs no options |

```ruby
require "json"

date = NepDate::Date.from_date(::Date.new(2024, 7, 30))
raise unless date.iso8601 == "2081-04-15"
raise unless NepDate::Date.from_ymd(20_810_415) == date
raise unless date.to_ymd == 20_810_415
raise unless date.to_json == '"2081-04-15"'
raise unless NepDate::Date.from_json(date.to_json) == date
raise unless JSON.generate({date: date}) == '{"date":"2081-04-15"}'
raise unless NepDate::Date.from_gregorian_batch([::Date.new(2024, 7, 30)]) == [date]
raise unless NepDate::Date.parse_batch(["2081-04-15"]) == [::Date.new(2024, 7, 30)]
raise unless NepDate::Date.to_gregorian_batch([date]) == [::Date.new(2024, 7, 30)]
puts "conversion: ok"
```

## Arithmetic

| C# signature | Ruby | Example or note |
|---|---|---|
| `NepaliDate AddMonths(double months, bool awayFromMonthEnd = false)` | `#add_months(int, overflow: :clamp)` | `:spill` is the `awayFromMonthEnd` mode (D-02) |
| `NepaliDate AddDays(double days)` | `#add_days(int)` | Fractions rejected (D-03) |
| `NepaliDate AddYears(int years, bool awayFromMonthEnd = false)` | `#add_years(int, overflow: :clamp)` | Uses twelve months |
| `TimeSpan Subtract(NepaliDate nepDateTo)` | `#days_until(other)`, `#diff(other)` | `other - self`, the named direction (D-07) |
| `static TimeSpan operator -(NepaliDate d1, NepaliDate d2)` | `#-` | `self - other`, the C# direction (D-07) |

```ruby
date = NepDate::Date.from_bs(2081, 4, 32)
raise unless date.add_days(30).iso8601 == "2081-05-30"
raise unless date.add_months(2).iso8601 == "2081-06-30"
raise unless date.add_months(2, overflow: :spill).iso8601 == "2081-07-02"
raise unless date.add_years(1).iso8601 == "2082-04-31"
raise unless date.days_until(NepDate::Date.from_bs(2081, 5, 1)) == 1
raise unless (date - NepDate::Date.from_bs(2081, 4, 15)) == 17
raise unless date.diff(NepDate::Date.from_bs(2081, 5, 31)).days == 0
puts "arithmetic: ok"
```

## Formatting

| C# signature | Ruby | Example or note |
|---|---|---|
| `override string ToString()` | `#to_s` | `"2081/04/15"` |
| `string ToString(DateFormats, Separators, bool leadingZeros = true)` | `#to_short_string(order:, separator:, pad:)` | Symbols: `:ymd`, `:dmy`, `:slash`, `:dash` |
| `string ToLongDateString(bool leadingZeros = true, bool displayDayName = false, bool displayYear = true)` | `#to_long_string(weekday:, year:, pad:, lang:)` | `"Tuesday, Shrawan 15, 2081"` |
| `string ToUnicodeString(DateFormats = YearMonthDay, Separators = ForwardSlash, bool leadingZeros = true)` | `#to_unicode_string(order:, separator:, pad:)` | `"२०८१/०४/१५"` |
| `string ToLongDateUnicodeString(bool leadingZeros = true, bool displayDayName = false, bool displayYear = true)` | `#to_long_unicode_string(weekday:, year:, pad:)` | `"मङ्गलवार, साउन १५, २०८१"` |
| `string ToString(string format, IFormatProvider formatProvider = null)` | `#format(pattern, lang:)` | Standard `""`, `G`, `g`, `d`, `D`, `s`; custom patterns |
| `bool ISpanFormattable.TryFormat(Span<char>, ...)` | not ported | Ruby strings are never too short |
| `enum DateFormats` | `NepDate::DateOrder` symbols | `:ymd`, `:ydm`, `:myd`, `:mdy`, `:dym`, `:dmy` |
| `enum Separators` | `NepDate::Separator` symbols | `:slash`, `:backslash`, `:dot`, `:underscore`, `:dash`, `:space` |
| `enum NepaliMonths` | `NepDate::Month` | `Month::BAISHAKH` to `Month::CHAITRA` |

```ruby
date = NepDate::Date.from_bs(2081, 4, 15)
raise unless date.to_s == "2081/04/15"
raise unless date.to_short_string(order: :dmy, separator: :dash) == "15-04-2081"
raise unless date.to_short_string(lang: :ne) == "२०८१/०४/१५"
raise unless date.to_long_string == "Shrawan 15, 2081"
raise unless date.to_long_string(weekday: true, lang: :ne) == "मङ्गलवार, साउन १५, २०८१"
raise unless date.format("MMMM d, yyyy") == "Shrawan 15, 2081"
raise unless date.format("MMM yy") == "Shr 81"
raise unless date.month_enum.short_label == "Shr"
puts "formatting: ok"
```

## Parsing

| C# signature | Ruby | Example or note |
|---|---|---|
| `static NepaliDate Parse(string rawNepaliDate)` | `.parse(text)` | Strict |
| `static NepaliDate Parse(string rawNepaliDate, bool autoAdjust, bool monthInMiddle = true)` | not ported (D-05, D-06) | Deterministic parsers only |
| `static bool TryParse(string rawNepDate, out NepaliDate result)` | `.try_parse(text)` | Returns nil |
| `static bool TryParse(string rawNepDate, out NepaliDate result, bool autoAdjust, bool monthInMiddle = true)` | not ported (D-05, D-06) | Deterministic parsers only |
| `static NepaliDate IParsable<NepaliDate>.Parse(string, IFormatProvider)` | `.parse`, `.try_parse` | No separate interface; these are the language entry points |
| `static NepaliDate ISpanParsable<NepaliDate>.Parse(ReadOnlySpan<char>, IFormatProvider)` | `.parse`, `.try_parse` | Ruby has no span type; the String form is the interface |
| `static NepaliDate SmartDateParser.Parse(string input)` | `.parse_lenient(text)` | Closed month list |
| `static bool SmartDateParser.TryParse(string input, out NepaliDate result)` | `.try_parse_lenient(text)` | Returns nil |
| `sealed class InvalidNepaliDateFormatException : FormatException` | `NepDate::Error` hierarchy | `#kind` and `#kind_name`; parse kinds in `ErrorKind` |

```ruby
raise unless NepDate::Date.parse("2081/04/15").iso8601 == "2081-04-15"
raise unless NepDate::Date.parse("२०८१/०४/१५").iso8601 == "2081-04-15"
raise unless NepDate::Date.parse_lenient("15 Shrawan 2081 B.S.").iso8601 == "2081-04-15"
raise unless NepDate::Date.try_parse("2081/13/01").nil?
raise unless NepDate::Date.try_parse_lenient("15 Foo 2081").nil?

begin
  NepDate::Date.parse("2081/13/01")
rescue NepDate::Error => error
  raise unless error.kind == :invalid_month
  raise unless error.kind_name == "InvalidMonth"
end
puts "parsing: ok"
```

## Ranges

| C# signature | Ruby | Example or note |
|---|---|---|
| `readonly struct NepaliDateRange : IEnumerable<NepaliDate>, IEquatable<NepaliDateRange>` | `NepDate::DateRange` | Includes `Enumerable` |
| `NepaliDateRange(NepaliDate start, NepaliDate end)` | `.new(start, end)`, `.of` | Refuses start after end (D-01) |
| `NepaliDate Start { get; }` | `#start` | |
| `NepaliDate End { get; }` | `#end` | |
| `bool IsEmpty { get; }` | not exposed (D-01) | Ranges are non-empty; `#empty?` is false |
| `int Length { get; }` | `#length`, `#size` | Inclusive day count |
| `static NepaliDateRange SingleDay(NepaliDate date)` | `.single_day(date)` | |
| `static NepaliDateRange FromDayCount(NepaliDate start, int days)` | `.from_day_count(start, days)` | |
| `static NepaliDateRange ForMonth(int year, int month)` | `.for_month(year, month)` | |
| `static NepaliDateRange ForFiscalYear(int fiscalYear)` | `FiscalYear.new(year).range` | |
| `static NepaliDateRange ForCalendarYear(int year)` | `.for_year(year)` | |
| `static NepaliDateRange CurrentMonth()` | `.current_month(zone:, clock:)` | |
| `static NepaliDateRange CurrentFiscalYear()` | `.current_fiscal_year(zone:, clock:)` | |
| `static NepaliDateRange CurrentCalendarYear()` | `.current_calendar_year(zone:, clock:)` | |
| `bool Contains(NepaliDate date)` | `#include?`, `#contains?`, `#contains` | |
| `bool Contains(NepaliDateRange other)` | `#contains_range?`, `#contains_range` | |
| `bool Overlaps(NepaliDateRange other)` | `#overlaps?`, `#overlaps` | |
| `bool IsAdjacentTo(NepaliDateRange other)` | `#adjacent_to?`, `#is_adjacent_to` | Never advances past the data edge (D-16) |
| `NepaliDateRange Intersect(NepaliDateRange other)` | `#intersect(other)` | Returns nil when disjoint |
| `NepaliDateRange Union(NepaliDateRange other)` | `#union(other)` | Smallest covering range |
| `NepaliDateRange[] Except(NepaliDateRange other)` | `#except(other)` | Zero, one or two ranges |
| `NepaliDateRange[] SplitByMonth()` | `#split_by_month` | Clipped ends (D-16) |
| `NepaliDateRange[] SplitByFiscalQuarter()` | `#split_by_fiscal_quarter` | Clipped ends (D-16) |
| `IEnumerable<NepaliDate> DatesWithInterval(int interval)` | `#dates_with_interval(step = 1)` | Stops before passing the end |
| `IEnumerable<NepaliDate> WorkingDays(bool excludeSunday = false)` | `#working_days(exclude_sunday: false)` | |
| `IEnumerable<NepaliDate> WeekendDays(bool includeSunday = true)` | `#weekend_days(include_sunday: true)` | |
| `IEnumerator<NepaliDate> GetEnumerator()` | `#each` | Enumerable methods work |
| `override string ToString()` | `#to_s` | `"start - end"` |
| `string ToString(DateFormats, Separators)` | `#to_short_string(order:, separator:, lang:)` | |
| `Equals`, `GetHashCode`, `operator ==`, `operator !=` | `#==`, `#eql?`, `#hash` | Value equality of both bounds |

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
puts "ranges: ok"
```

## Fiscal year

| C# signature | Ruby | Example or note |
|---|---|---|
| `enum FiscalYearQuarters` | `NepDate::Quarter` | `Quarter::Q1` to `Quarter::Q4` |
| `NepaliDate FiscalYearStartDate(int yearOffset = 0)` | `FiscalYear#start` | No offset; make a fiscal-year value (D-08) |
| `NepaliDate FiscalYearEndDate(int yearOffset = 0)` | `FiscalYear#end` | No offset (D-08) |
| `(NepaliDate startDate, NepaliDate endDate) FiscalYearStartAndEndDate(int yearOffset = 0)` | `FiscalYear#range` | No offset (D-08) |
| `NepaliDate FiscalYearQuarterStartDate(FiscalYearQuarters q = Current, int yearOffset = 0)` | `FiscalYear#quarter_start(q)` | |
| `NepaliDate FiscalYearQuarterEndDate(FiscalYearQuarters q = Current, int yearOffset = 0)` | `FiscalYear#quarter_end(q)` | |
| `(NepaliDate, NepaliDate) FiscalYearQuarterStartAndEndDate(FiscalYearQuarters q = Current, int yearOffset = 0)` | `FiscalYear#quarter_range(q)` | |
| `static NepaliDate GetFiscalYearStartDate(int fiscalYear)` | `FiscalYear.new(year).start` | |
| `static NepaliDate GetFiscalYearEndDate(int fiscalYear)` | `FiscalYear.new(year).end` | |
| `static (NepaliDate, NepaliDate) GetFiscalYearStartAndEndDate(int fiscalYear)` | `FiscalYear.new(year).range` | |
| `static NepaliDate GetFiscalYearQuarterStartDate(int fiscalYear, int month)` | not ported (D-08) | Use the quarter value |
| `static NepaliDate GetFiscalYearQuarterEndDate(int fiscalYear, int month)` | not ported (D-08) | Use the quarter value |
| `static (NepaliDate, NepaliDate) GetFiscalYearQuarterStartAndEndDate(int fiscalYear, int month)` | not ported (D-08) | Use the quarter value |

```ruby
fiscal = NepDate::FiscalYear.containing(NepDate::Date.from_bs(2082, 2, 1))
raise unless fiscal.label == "2081/82"
raise unless fiscal.start.iso8601 == "2081-04-01"
raise unless fiscal.end.iso8601 == "2082-03-32"
raise unless fiscal.quarter_range(:q1).to_s == "2081/04/01 - 2081/06/30"
raise unless fiscal.quarter_range(:q4).to_s == "2082/01/01 - 2082/03/32"
raise unless fiscal.quarter_start(:q1) == fiscal.start
puts "fiscal year: ok"
```

## Patro

`nepdate-patro` adds these. The core has no almanac data (D-13).

| C# signature | Ruby | Example or note |
|---|---|---|
| `readonly struct CalendarInfo` | `NepDate::Patro::CalendarInfo` | Immutable value |
| `string TithiNp { get; }` | `#tithi_np`, `#tithi&.nepali` | Empty string outside the data |
| `string TithiEn { get; }` | `#tithi_en`, `#tithi&.english` | Empty string outside the data |
| `bool IsPublicHoliday { get; }` | `#public_holiday?`, `#is_public_holiday` | False outside the data |
| `string[] EventsNp { get; }` | `#events_np`, `#events` with `#nepali` | File order preserved |
| `string[] EventsEn { get; }` | `#events_en`, `#events` with `#english` | File order preserved |
| `CalendarInfo GetCalendarInfo()` | `NepDate::Patro.info(date)`, `date.calendar_info` | Never throws |

```ruby
day = NepDate::Patro.info(NepDate::Date.from_bs(2081, 2, 15))
raise unless day.public_holiday?
raise unless day.tithi.nepali == "पञ्चमी"
raise unless day.tithi.english == "Panchami"
raise unless day.events_en == ["Republic Day"]
raise unless NepDate::Patro.coverage.start.iso8601 == "2077-01-01"
raise unless NepDate::Patro.public_holidays.length == 294
raise unless NepDate::Date.from_bs(2081, 2, 15).calendar_info == day
puts "patro: ok"
```

## Ruby value objects and helpers

These types and aliases are the Ruby spelling of the C# members above and are not additional
behaviour.

| Type | Members | Note |
|---|---|---|
| `NepDate::Month` | `.from`, `#number`, `#label`, `#short_label`, constants | `NepDate::Month::SHRAWAN` |
| `NepDate::Weekday` | `.from`, `#number`, `#label`, `#short_label`, `#sunday?` to `#saturday?`, constants | Sunday is 0 |
| `NepDate::Quarter` | `.from`, `#number`, `#name`, `#label`, constants | `:q1` to `:q4` |
| `NepDate::DateDiff` | `#negative?`, `#sign`, `#years`, `#months`, `#days`, `#total_days` | Calendar breakdown |
| `NepDate::DateOrder` | `:ymd`, `:ydm`, `:myd`, `:mdy`, `:dym`, `:dmy` | Short and range formats |
| `NepDate::Separator` | `:slash`, `:backslash`, `:dot`, `:underscore`, `:dash`, `:space` | Also accepts the character |
| `NepDate::Lang` | `:en`, `:ne` | English and Nepali output |
| `NepDate::MonthOverflow` | `:clamp`, `:spill` | Whole-month arithmetic |
| `NepDate::ErrorKind` | The nine kind symbols | `#name_for` returns the vector spelling |
| `NepDate::Error` | `#kind`, `#kind_name` | Base class |
| `NepDate::Patro::Tithi` | `#nepali`, `#english`, `#name(lang:)` | A tithi name |
| `NepDate::Patro::Event` | `#nepali`, `#english`, `#name(lang:)` | One event name |
| `NepDate::Date#serial` | 0-based day number, 0 on 1901-01-01 | Used by ranges and the patro, and useful for ordering |
| `NepDate::Date.from_serial(n)` | Builds a date from that number | The inverse of `#serial`; 0 to 109211 |
| `NepDate::Date#to_ary` | `[year, month, day]` | `year, month, day = date` |
| `NepDate::DateRange#first`, `#last` | The first or last date, or a count | `range.first`, `range.last(2)` |

## Rows left out

Sixteen rows are not part of this port, each for a decision in the hub's
[`spec/PARITY.md`](https://github.com/sanamhub/nepdate/blob/main/spec/PARITY.md):

- The `autoAdjust` constructor and its two parser overloads are not ported (D-05, D-06).
- `IsDefault` is not ported because an invalid date cannot be constructed (D-01).
- The untyped `CompareTo(object)` is not ported; comparison is typed.
- The object JSON form, the Newtonsoft converters, the XML serializer and the two
  `ConfigureForNepaliDate` option helpers are not ported (D-11).
- `TryFormat` is not ported; a Ruby string has no buffer to be too short for.
- `IsEmpty` is not exposed because every range has at least one day (D-01).
- The three static `GetFiscalYearQuarter*` helpers that take a calendar year and a month are not
  ported (D-08); the fiscal-year value covers them.

That leaves 108 of the 124 rows implemented. Every one of the 108 has a vector, a clock note or a
decision in the hub spec.
