# frozen_string_literal: true

require_relative "lib/nepdate/version"

Gem::Specification.new do |spec|
  spec.name = "nepdate"
  spec.version = NepDate::VERSION
  spec.summary = "Bikram Sambat dates for Ruby: conversion, arithmetic, formatting, parsing and ranges"
  spec.description = <<~DESCRIPTION
    A pure Ruby port of the C# NepDate library. Converts between Bikram Sambat and Gregorian
    dates, adds days, months and years with an explicit overflow mode, formats in English and
    Nepali, parses strictly and leniently, and works with inclusive date ranges and fiscal years.
    No runtime dependencies and no runtime data file.
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

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/sanamhub/nepdate-ruby/issues",
    "changelog_uri" => "https://github.com/sanamhub/nepdate-ruby/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/sanamhub/nepdate-ruby/blob/main/docs/API.md",
    "homepage_uri" => "https://nepdate.com",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/sanamhub/nepdate-ruby"
  }
end
