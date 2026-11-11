# frozen_string_literal: true

source "https://rubygems.org"

gem "nepdate", path: "packages/nepdate"
gem "nepdate-patro", path: "packages/nepdate-patro"

# Development tools are pinned and published at least 14 days before the version in this
# repository was written.
gem "benchmark-ips", "2.15.1"
gem "json", "3.1.0"
# minitest 5.26.0 and older declare `required_ruby_version < 4.0`, so the Ruby 4.0
# matrix cell could not install the bundle. 5.26.1 lifts that cap.
gem "minitest", "6.0.6"
gem "parser", "3.3.13.0"
gem "rake", "13.4.2"
gem "rbs", "4.2.0"
# rubocop-ast 1.46 asks Prism for the versioned adapter that Ruby 4.0 no longer
# ships. 1.50.0 supports Ruby 4.0 and still satisfies RuboCop's >= 1.44, < 2.0 range.
gem "rubocop-ast", "1.50.0"
gem "simplecov", "1.3.2"
# standard 1.50 pins RuboCop 1.75, so the lint rules are unchanged even though
# rubocop-ast is newer.
gem "standard", "1.57.0"
gem "yard", "0.9.45"
