# Release runbook

The first release is `1.0.0-rc.1`, with every other NepDate port. This runbook is written for the
release state; no tag, release or publish happens during the review of this repository.

## Owner steps before the first tag

Do these in order. Do not create the tag until all of them are done.

1. **RubyGems account and MFA.** Sign in to <https://rubygems.org/> as the owner. Enable MFA for the
   account (the account settings page has the setup and recovery codes). Both gems will require MFA
   through their metadata (`rubygems_mfa_required: true`).
2. **Pending trusted publisher for `nepdate`.** At
   <https://rubygems.org/profile/oidc/pending_trusted_publishers>, add a pending publisher with:
   - gem name: `nepdate`
   - repository: `sanamhub/nepdate-ruby`
   - workflow file: `release.yml`
   - environment: `production`
3. **Pending trusted publisher for `nepdate-patro`.** Repeat with gem name `nepdate-patro`, the same
   repository, workflow file and environment. The two entries must match exactly.
4. **`production` environment.** In the GitHub repository, create an environment named `production`
   under Settings, Environments. Add a deployment tag rule that allows `v*` and nothing else. Add
   required reviewers if the owner wants an approval before each publish. No secret is needed: the
   workflow uses OIDC.
5. **Dependabot alerts and automated security fixes.** In Settings, Code security, enable Dependabot
   alerts and Dependabot security updates. The scheduled dependency review and Scorecard workflows
   need the repository's default branch and code scanning to be enabled.
6. **Branch protection for `main`.** Require the CI, shared-check, CodeQL and dependency-review
   checks, require a pull request, and disallow force pushes and deletion.
7. **Confirm the names.** `nepdate` and `nepdate-patro` were free on rubygems.org when this port was
   written (2026-11-03). Recheck both gem pages before trusting the pending publishers to reserve
   them; a pending publisher does not take a name until the first successful push.

## The version

- The two gems use RubyGems' release-candidate spelling `1.0.0.rc.1`, the spelling users type with
  `gem install -v` and in a Gemfile.
- The tag, the changelog heading, the README prose and the hub entry use the family spelling
  `1.0.0-rc.1`. `scripts/release_check.rb` maps the tag to the gem version, so both names check.
- The tag is `v1.0.0-rc.1`. The `production` environment allows only `v*`.

## Before the tag

1. The hub branch `feat/nepdate-ruby` has merged `main` with the Ruby entry in `spec/versions.json`
   at the line that will release. The hub branch itself merges at the 1.0 release, not before this
   tag; the port's `shared-check` is green under hub ADR-0008 while it has no `sdks` entry.
2. `bundle exec rake ci` is green on `main`.
3. `bundle exec ruby scripts/release_check.rb --draft v1.0.0-rc.1` is green. This builds both gems,
   checks their contents, installs them into a temporary `GEM_HOME` and runs them.
4. `docs/benchmarks.md` has a quiet run on the reference machine, with the CPU load recorded.
5. The changelog has a `## [1.0.0-rc.1] - YYYY-MM-DD` section. The dry run accepts `[Unreleased]`
   until the bump pull request; a tag does not.
6. The pending publishers and the `production` environment exist.

## Tag and publish

```sh
git switch main
git pull --ff-only
git tag -a v1.0.0-rc.1 -m "nepdate-ruby 1.0.0-rc.1"
git push origin v1.0.0-rc.1
```

The tag starts `release.yml`:

1. `preflight` checks that the tag is on `main`, the version matches both gemspecs and the changelog
   has the version heading.
2. `ci` repeats the full gate.
3. `publish`, after the `production` approval, installs the locked gems, builds both gems, runs the
   release check again, pushes `nepdate` and then `nepdate-patro`, and creates the GitHub Release
   after both pushes. If the second push fails, no release is created.
4. `verify-published` installs the published gems on Linux, macOS and Windows and runs
   `scripts/published_smoke.rb`.

## After the release

1. Watch `verify-published.yml`. If it opens a `published-check` issue, fix the packaging or the
   registry state and release a new patch; do not delete the tag.
2. Update the hub `spec/versions.json` (line and the two new `sdks` entries) and `spec/packages.json`
   and open the hub release pull request. The hub branch for Ruby is merged at 1.0, not before.
3. Announce the version with the registry links.

## Dry run

`workflow_dispatch` with a tag name runs the preflight in draft mode and the full CI, builds and
checks both gems, and pushes nothing. Use it before the first real tag:

```text
Actions -> release -> Run workflow -> tag: v1.0.0-rc.1
```
