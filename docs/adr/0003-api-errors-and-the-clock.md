# ADR-0003: Ruby names, one error hierarchy and an explicit clock

- **Status:** accepted
- **Date:** 2026-11-03

## Context

The hub fixes the concepts, not the Ruby spellings. The port has to feel like Ruby while keeping
every API row and every deliberate deviation. Clock functions are the easiest place to hide a local
zone, and Ruby has no time zone database in its standard library.

## Decision

1. The core type is `NepDate::Date`, so the common call reads `NepDate::Date.parse("2081-04-15")`.
   `NepDate::NepaliDate` is not added: the module already names the calendar, and an alias would be a
   second public name for one concept.
2. `Date` includes `Comparable`, implements `==`, `eql?`, `hash`, `to_s`, `inspect`, `succ`,
   `deconstruct`, `deconstruct_keys` and `to_ary`. A `Range` of dates therefore works, and a date can
   be destructured with `year, month, day = date`.
3. The range is `NepDate::DateRange` and includes `Enumerable`. Boolean predicates end in `?`:
   `include?`, `contains?`, `overlaps?`, `adjacent_to?`, `today?`, `public_holiday?`. The C# names
   without `?` are kept as aliases where the mapping table benefits from them.
4. `NepDate::Error < StandardError` is the single base. `#kind` is a symbol from
   `NepDate::ErrorKind`; `#kind_name` gives the PascalCase spelling used by the shared vectors. The
   concrete subclasses are `OutOfRangeError`, `InvalidMonthError`, `InvalidDayError`,
   `InvalidGregorianError` and `ParseError`. Validation and parse grammar failures are distinct.
5. Parsing is strict and lenient, each with a non-throwing form: `parse`, `try_parse`,
   `parse_lenient`, `try_parse_lenient`. D-05 and D-06 are implemented exactly, including the
   four-digit group cap, the closed month list and the ASCII plus Kelvin case fold.
6. Month arithmetic takes an integer and `overflow: :clamp` or `:spill`; there is no fractional
   month or day. The named `days_until` is `other - self`; the `-` operator is `self - other` (D-07).
7. Clock functions take an explicit zone or offset and an optional `clock:` callable. The default
   zone is `Asia/Kathmandu`, a documented fixed offset of +05:45, never the machine's local zone.
   Accepted forms are the Nepal aliases, `UTC`, `GMT`, `Z`, `+HH:MM`, an integer number of seconds,
   or an object with `utc_offset`. There is no bundled time zone database and no DST rule.

## Consequences

- A caller with a `tzinfo` zone can pass its current `utc_offset`; a caller with a `Time` can pass
  the offset of that time.
- A clock never changes behaviour silently between machines, and a test passes a lambda.
- The two date difference names stay visibly different in the API documentation.
