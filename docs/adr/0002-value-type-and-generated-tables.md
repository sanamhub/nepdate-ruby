# ADR-0002: An immutable date, a serial day and generated tables

- **Status:** accepted
- **Date:** 2026-11-03

## Context

The C# implementation stores a year, month and day and validates through a table. The other ports
found that a serial day number makes conversion, comparison, arithmetic and ranges exact and cheap.
Ruby can hold arbitrary integers, so the C# `int` overflow concerns do not apply to the storage, but
the supported range still has to be enforced explicitly.

## Decision

1. `NepDate::Date` is frozen after construction and holds the BS year, month, day and the serial
   day, 0 for 1901-01-01. Construction validates year, then month, then day, and computes the serial
   from the generated table.
2. `NepDate::DateRange` holds two `Date` values and is frozen. It refuses a start after the end, so
   there is no empty range and no invalid range.
3. `scripts/generate_tables.rb` compiles `shared/data/calendar/bs-calendar.json` into
   `NepDate::CalendarTable`: one packed integer of twelve two-bit month lengths per year and one
   year-start serial per year. The table is checked in and `--check` fails on drift.
4. `Calendar` is the only code that reads the table. `to_serial`, `from_serial`, `days_from_civil`
   and `civil_from_days` are the ALGORITHM.md algorithms, with Ruby integer division.
5. Integer arguments are checked for being integers and for the supported range. There is no
   coercion from floats, and a result outside 0..109211 raises `NepDate::OutOfRangeError`.

## Consequences

- Two dates compare and hash by their serial, and month and day addition are exact.
- The generated table is about 20 KB of source and loads with the library; there is no file read.
- A date cannot represent 0000-00-00, which is the D-01 decision.
