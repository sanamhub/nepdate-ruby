# Security policy

## Supported versions

The latest release of each gem: `nepdate` and `nepdate-patro`. Older versions get no fixes.

## Reporting a vulnerability

Report privately through
[GitHub security advisories](https://github.com/sanamhub/nepdate-ruby/security/advisories/new).
Don't open a public issue. Expect a first reply within a week.

Say which gem and version are affected and how to reproduce it. A wrong date, holiday or tithi isn't
a security problem: open a bug report, or a data error in the hub
([`sanamhub/nepdate`](https://github.com/sanamhub/nepdate)).

## Static analysis coverage

CodeQL supports Ruby, so `.github/workflows/codeql.yml` analyzes the Ruby source and the GitHub
Actions workflows. [OpenSSF Scorecard](https://securityscorecards.dev/) and GitHub's Dependency
Review run on every pull request, and Dependabot covers the Bundler ecosystem and GitHub Actions.

The library has no runtime dependency other than `nepdate-patro` on `nepdate`, reads no runtime data
file and makes no network call. `bundle exec rake ci` includes the generator checks, Standard, RBS,
the tests and the coverage gate.
