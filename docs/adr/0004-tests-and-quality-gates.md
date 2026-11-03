# ADR-0004: Minitest, SimpleCov, Standard and RBS

- **Status:** accepted
- **Date:** 2026-11-03

## Context

Every port has to read all shared vectors, keep a 90% line and branch coverage floor, and check the
public signatures. Ruby's common tools are minitest and SimpleCov, Standard for style, and either
Steep or `rbs test` for signatures. Mutation testing is covered separately in ADR-0010.

## Decision

1. Tests use minitest. `test/vectors/` has one file per shared vector, `test/unit/` has the edge and
   property tests, and `test/patro/` covers the almanac. A failing vector row names the row's date,
   operation or input.
2. SimpleCov measures line and branch coverage and fails below 90% for each. Generated table files
   are loaded once but do not hide logic; the gate is not lowered to make a design smell pass.
3. Property tests use a fixed seed (`20_811_015`) and 2,000 samples, because Ruby has no property
   library with the cross-language history of jqwik. The exhaustive test covers every serial from 0
   to 109,211 in both directions.
4. Standard (RuboCop) is the formatter and linter. Because Standard's native end-of-line cop demands
   CRLF on Windows and LF on Linux, `Layout/EndOfLine` is skipped and `.gitattributes` enforces LF.
   The generated tables are excluded because the generator owns their bytes; `generate --check`
   guards them instead.
5. Signatures live in `packages/*/sig/` and cover the public API. CI runs `rbs validate` with the
   `date` and `json` stdlib signatures and then `rbs test` on `test/rbs/smoke.rb`, which calls every
   public class with valid arguments. Steep is not used: the test suite also passes deliberately
   invalid argument types, which a runtime type check instruments at the call boundary, and a
   dedicated smoke file keeps that check meaningful without weakening the signatures.
6. YARD builds the API documentation. Every fenced Ruby block in `README.md` and `docs/API.md` runs
   in a fresh process with only `require "nepdate"` and `require "nepdate/patro"` as the prelude.
7. One command, `bundle exec rake ci`, runs the same chain as CI: generator check, Standard, RBS,
   YARD, examples, tests and release check.

## Consequences

- A local `rake ci` is the full gate; CI only adds the OS and Ruby matrix and the hub checks.
- The RBS smoke file is a test of signatures, not of behaviour, and is not part of the Minitest
  count.
- The EOL exception is visible in `.standard.yml` rather than a machine-specific local setting.
