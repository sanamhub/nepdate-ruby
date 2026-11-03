# ADR-0001: One repository, two gems, pure Ruby

- **Status:** accepted
- **Date:** 2026-11-03

## Context

The Ruby port needs the core and the patro, and hub ADR-0004 decision 2 says both live in one
repository and release from one tag. Ruby projects usually put a gem at the repository root, but two
gems cannot both own the root. The toolchain has to work on Windows, macOS and Linux without a
system install or a compiler.

## Decision

1. The repository root holds the Gemfile, Rakefile, tests, scripts, docs and shared data.
2. `packages/nepdate` and `packages/nepdate-patro` each hold a gemspec and a `lib/` tree. The root
   Gemfile resolves both by path during development, and each gemspec is built from its own
   directory.
3. The code is pure Ruby, `>= 3.4`, with no runtime dependency. `nepdate-patro` depends only on the
   matching `nepdate` version. There is no C extension in this release.
4. `shared/` is a read-only vendored copy of the hub's `data/` and `spec/`, with the hub commit in
   `shared/VERSION`. Generated Ruby tables are the only files derived from it.
5. CI runs Ruby 3.4, the current stable release and `head` on Linux, macOS and Windows. The `head`
   cell is allowed to fail. The gems themselves declare `>= 3.4`.

## Consequences

- A release builds two `.gem` files from one tag and publishes both.
- The generated tables are ordinary Ruby constants, so there is no build step, native toolchain or
  runtime data file.
- The three-package layout adds one directory level to every library path; the gemspecs handle it,
  and the test helper puts both `lib/` directories on the load path.
- A native extension remains a later option only if the benchmark measures a large enough gain and a
  new ADR records it.
