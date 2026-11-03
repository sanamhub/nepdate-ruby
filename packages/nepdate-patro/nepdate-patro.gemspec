# frozen_string_literal: true

require_relative "lib/nepdate/patro/version"

Gem::Specification.new do |spec|
  spec.name = "nepdate-patro"
  spec.version = NepDate::Patro::VERSION
  spec.summary = "The Nepali patro for Ruby: tithi, public holidays and events for Bikram Sambat dates"
  spec.description = <<~DESCRIPTION
    The patro (पात्रो, the Nepali almanac) as a separate gem for NepDate for Ruby. It answers the
    tithi, the gazetted holiday flag and the ordered event list for every covered BS date, with
    the data compiled into the gem. It depends on nepdate and the core has no almanac data.
  DESCRIPTION
  spec.authors = ["Sanam Pakuwal"]
  spec.email = ["31341013+sanamhub@users.noreply.github.com"]
  spec.homepage = "https://nepdate.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb", "sig/**/*.rbs", "README.md", "CHANGELOG.md", "LICENSE", "NOTICE"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "nepdate", "= #{NepDate::Patro::VERSION}"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/sanamhub/nepdate-ruby/issues",
    "changelog_uri" => "https://github.com/sanamhub/nepdate-ruby/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/sanamhub/nepdate-ruby/blob/main/docs/API.md",
    "homepage_uri" => "https://nepdate.com",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/sanamhub/nepdate-ruby"
  }
end
