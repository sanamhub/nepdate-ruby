# ADR-0007: One tag, two gems, RubyGems trusted publishing

- **Status:** accepted
- **Date:** 2026-11-03

## Context

Hub ADR-0004 decision 3 and ADR-0007 require one tag for the core and the patro. RubyGems supports
trusted publishing through GitHub Actions OIDC, with a pending publisher that can be configured
before either gem exists. The owner has a personal RubyGems account and no gems yet.

## Decision

1. The release trigger is a `v*` tag, for example `v1.0.0-rc.1`. The `production` environment has a
   tag rule that only allows `v*`, and the publish job uses `rubygems/configure-rubygems-credentials`
   with `id-token: write`.
2. The same job builds `nepdate` and `nepdate-patro` from their own directories, runs the release
   check, installs both built gems into a temporary `GEM_HOME`, and pushes both. It does not publish
   when the event is `workflow_dispatch`; that is the dry run.
3. The GitHub Release is created after both pushes, from the changelog section. A failed second push
   fails the job before the release is created.
4. The owner must, before the first tag:
   - enable MFA on the RubyGems account;
   - create a pending trusted publisher for `nepdate` and one for `nepdate-patro`, both with
     repository `sanamhub/nepdate-ruby`, workflow file `release.yml`, environment `production`;
   - create the `production` environment with a tag rule for `v*`.
5. No RubyGems API key is stored. The workflow file name, repository and environment in the pending
   publisher must match exactly, or the OIDC exchange fails.
6. The gem version is `1.0.0.rc.1`, Ruby's own spelling for a release candidate: it contains a
   letter, so RubyGems reads it as a prerelease, the way Python publishes `0.2.0rc1` on PyPI.
   The tag, changelog, README prose and hub keep the family spelling `1.0.0-rc.1`, and the tag is
   `v1.0.0-rc.1`. `scripts/release_check.rb` maps the family spelling to the gem spelling, and
   `scripts/release_notes.rb` maps it back for the changelog section. A hyphenated
   `1.0.0-rc.1` would instead be stored by RubyGems as `1.0.0.pre.rc.1`, which is a different
   version and not the one users should type.
7. `verify-published.yml` runs on a schedule on Linux, macOS and Windows, installs both gems from
   RubyGems and runs `scripts/published_smoke.rb`. It also runs after the release.
8. The first release is `1.0.0-rc.1` in the family and `1.0.0.rc.1` on RubyGems; the tag
   `v1.0.0-rc.1` is not created in this review. The hub branch stays unmerged until that release,
   and the hub line stays `0.2` until 1.0 (hub ADR-0008).

## Consequences

- A tag publishes both gems or neither, with one environment approval.
- The owner's RubyGems account needs no stored secret, but the pending publishers must exist first.
- The registry page shows `1.0.0.rc.1`, the version users install; the tag, changelog and hub keep
  the family spelling `1.0.0-rc.1`.
