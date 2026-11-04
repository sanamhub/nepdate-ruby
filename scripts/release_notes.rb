# frozen_string_literal: true

# Prints the GitHub Release notes for one version: the changelog section and the install block.

require "json"

ROOT = File.expand_path("..", __dir__)
version = ARGV.fetch(0) { abort "usage: ruby scripts/release_notes.rb VERSION [FAMILY]" }
family = ARGV.fetch(1, version.sub(/\.((?:alpha|beta|rc)\.\d+)\z/, '-\1'))

changelog = File.read(File.join(ROOT, "CHANGELOG.md"), encoding: "UTF-8")
lines = changelog.lines
start = lines.index { |line| line.start_with?("## [#{family}]") }
abort "CHANGELOG.md has no section for #{family}" unless start

section = []
(lines[(start + 1)..] || []).each do |line|
  break if line.start_with?("## [")

  section << line
end
body = section.join.strip
abort "the changelog section for #{family} is empty" if body.empty?

puts body
puts
puts "### Install"
puts
puts "```sh"
puts "gem install nepdate -v #{version}"
puts "gem install nepdate-patro -v #{version} # tithi, holidays and events"
puts "```"
puts
puts "The gem version is `#{version}`; the tag is `v#{family}`. RubyGems stores the release"
puts "candidate as `#{Gem::Version.new(version)}`, so use that spelling with `gem install -v`."
puts
puts "### Verification"
puts
puts "After this release, a fresh `gem install` of both gems converted a date and read a patro event"
puts "on Linux, macOS and Windows (verify-published)."
