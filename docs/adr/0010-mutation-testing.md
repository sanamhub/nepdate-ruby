# ADR-0010: No mutation-testing gate in this release

- **Status:** accepted
- **Date:** 2026-11-03

## Context

The tooling list asks for mutation testing only if its licence allows it for this MIT project at no
cost. The Ruby mutation tool is `mutant`, version 0.17.1 at the time of writing. Its gem metadata
declares `Nonstandard`, and its EULA requires a paid subscription or a Free Project License obtained
through a subscription with a Source URL. It is not an OSI-approved licence and cannot be installed
and used for this repository without that step.

## Decision

There is no mutation workflow and no `docs/mutation/` directory in this release. The test suite and
the 90% line and branch coverage gate are the mutation-adjacent checks. The question is recorded
here so a later maintainer does not add a workflow that cannot run on a clean checkout.

## Consequences

- CI has no scheduled mutation job and no mutation threshold to keep.
- If the owner obtains a Free Project License, a new ADR and a `mutation.yml` can add `mutant` with a
  count-based threshold, as the Java port does with PIT.
- Hand-rolled seeded property loops are not a substitute for mutation testing and are not described
  as one.
