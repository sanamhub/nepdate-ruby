# ADR-0005: The patro is a second gem

- **Status:** accepted
- **Date:** 2026-11-03

## Context

Hub ADR-0004 requires the almanac in a separate package. It is about 130 KB of Ruby source, changes
with the yearly data and is not needed by most users. It must still share the core date type and be
released from the same tag.

## Decision

1. `nepdate-patro` is a separate gem with module `NepDate::Patro`. It declares an exact dependency on
   `nepdate` at the same version.
2. `scripts/generate_patro_tables.rb` reads `shared/data/patro/*.json`, computes serials from the
   calendar JSON itself and writes `NepDate::Patro::Table`. It compares every count against
   `shared/spec/vectors/patro-summary.json` and fails on a gap in the tithi range.
3. The table uses one index per day for the contiguous tithi range, sorted serials and a binary
   search for holidays and event days, and a flat event slice. Event order inside a day is file
   order. Names are deduplicated as `[np, en]` pairs.
4. `NepDate::Patro.info`, `.coverage` and `.public_holidays` are the query surface. `Date#calendar_info`
   is added by this gem, so the core has no reference to the patro.
5. The data is informational, not an official calendar. A date outside the coverage returns a nil
   tithi, false holiday and empty list, never an error.

## Consequences

- The core gem stays small and has no event strings. The release check asserts that the longest event
  name is absent from the core and present in the patro.
- Both gems share one tag and one version, and a data update is a patch release of both.
