# ADR-0009: Ruby 3.4 or newer

- **Status:** accepted
- **Date:** 2026-11-03

## Context

Ruby 3.3 leaves security support on 2027-03-31. Ruby 3.4 is the oldest line that will still receive
security fixes through the first year of this gem, and Ruby 4.0 is the current stable release at the
time of writing. The code uses no 4.0-only syntax.

## Decision

1. Both gems declare `required_ruby_version = ">= 3.4"`.
2. CI runs Ruby 3.4, the current stable release and `head` on Linux, macOS and Windows. `head` is
   allowed to fail.
3. There is no Ruby 3.3 compatibility shim. The standard library `date` and `json` gems are the only
   runtime imports.
4. The RubyInstaller portable 7z archive is the Windows local toolchain. It is a toolchain choice,
   not a runtime dependency; the gems contain no native extension.

## Consequences

- A user on Ruby 3.3 must upgrade, which is the same support decision the other new ports make.
- The Windows archive needs no Devkit for the library, only the development gems that build native
  extensions (RBS's parser and the RuboCop parser).
