# ADR-0006: One canonical text form and the native JSON hook

- **Status:** accepted
- **Date:** 2026-11-03

## Context

D-11 removes the object form, the Newtonsoft and XML adapters and the `TypeConverter` type. It keeps
the canonical text `YYYY-MM-DD` and the `YYYYMMDD` integer. Ruby's standard JSON library calls
`to_json` and a `from_json` helper is the natural reader.

## Decision

1. `Date#iso8601` is the canonical text, `YYYY-MM-DD`, ASCII digits.
2. `Date#to_json` returns a JSON string, `"2081-04-15"`. It accepts and ignores the optional state
   argument the JSON generator passes, so `JSON.generate({date: date})` gives
   `{"date":"2081-04-15"}`.
3. `Date.from_json` parses JSON and accepts only a JSON string. A JSON `null`, object, number or
   malformed text raises `NepDate::ParseError`; there is no zero date to turn null into.
4. `Date#to_h` and `#to_a` are value helpers, not a second object serialization form.
5. `from_ymd` and `to_ymd` keep the packed integer. There is no converter class.

## Consequences

- Interchange with the other ports uses the same ten-character text.
- The object form cannot be produced by accident.
- A caller that wants an object can call `date.to_h` explicitly.
