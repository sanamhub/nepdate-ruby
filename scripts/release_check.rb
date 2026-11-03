# frozen_string_literal: true

# Checks the version, the changelog, both gemspecs and the packed gems without publishing anything.
#
#   ruby scripts/release_check.rb --print
#   ruby scripts/release_check.rb --draft              # CI dry run, accepts [Unreleased]
#   ruby scripts/release_check.rb --draft v1.0.0-rc.1  # a dry run against a tag name
#   ruby scripts/release_check.rb v1.0.0-rc.1          # a real tag: the version heading must exist

require "fileutils"
require "open3"
require "rubygems/package"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
DIST = File.join(ROOT, "dist")
CORE_GEMSPEC = File.join(ROOT, "packages/nepdate/nepdate.gemspec")
PATRO_GEMSPEC = File.join(ROOT, "packages/nepdate-patro/nepdate-patro.gemspec")
LONG_EVENT = "World Day Against Human Trafficking"
CLEAN_BUNDLER_ENV = {
  "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLE_GEMFILE" => nil, "BUNDLE_PATH" => nil,
  "BUNDLE_WITH" => nil, "BUNDLE_BIN_PATH" => nil, "BUNDLER_SETUP" => nil,
  "BUNDLER_VERSION" => nil
}.freeze

def fail_with(message)
  warn "release_check: #{message}"
  exit 1
end

def version_from(path)
  require path
  path.include?("patro") ? NepDate::Patro::VERSION : NepDate::VERSION
end

def gem_file(name, version)
  File.join(DIST, "#{name}-#{version}.gem")
end

def build(gemspec, name, version)
  output = gem_file(name, version)
  FileUtils.mkdir_p(DIST)
  FileUtils.rm_f(output)
  Dir.chdir(File.dirname(gemspec)) do
    ok = system(Gem.ruby, "-S", "gem", "build", File.basename(gemspec), "--output", output, out: File::NULL)
    fail_with("gem build failed for #{gemspec}") unless ok
  end
  fail_with("#{output} was not written") unless File.file?(output)
  output
end

def package_files(path)
  package = Gem::Package.new(path)
  [package.spec, package.contents]
end

def assert(condition, message)
  fail_with(message) unless condition
end

core_version = version_from(File.join(ROOT, "packages/nepdate/lib/nepdate/version.rb"))
patro_version = version_from(File.join(ROOT, "packages/nepdate-patro/lib/nepdate/patro/version.rb"))
assert(core_version == patro_version, "the two gems are on different versions: #{core_version} and #{patro_version}")

print_only = ARGV.include?("--print")
draft = ARGV.include?("--draft")
tags = ARGV.reject { |arg| arg.start_with?("--") }
tag = tags.first

if print_only
  puts core_version
  exit 0
end

if tag
  expected = tag.start_with?("v") ? tag.delete_prefix("v") : tag
  assert(expected == core_version, "tag #{tag} does not name the manifest version #{core_version}")
end

changelog = File.read(File.join(ROOT, "CHANGELOG.md"), encoding: "UTF-8")
if draft
  assert(changelog.include?("## [Unreleased]"), "CHANGELOG.md has no [Unreleased] heading")
else
  heading = "## [#{core_version}]"
  assert(changelog.include?(heading), "CHANGELOG.md has no #{heading} heading")
end

core_spec = Gem::Specification.load(CORE_GEMSPEC) or fail_with("cannot load #{CORE_GEMSPEC}")
patro_spec = Gem::Specification.load(PATRO_GEMSPEC) or fail_with("cannot load #{PATRO_GEMSPEC}")
# RubyGems writes a hyphenated prerelease as `.pre.rc.1` internally while the manifest, tag and
# changelog keep the family's SemVer spelling. Gem::Version comparison accepts both spellings.
assert(Gem::Version.new(core_version) == core_spec.version,
  "nepdate.gemspec version is #{core_spec.version} for #{core_version}")
assert(Gem::Version.new(patro_version) == patro_spec.version,
  "nepdate-patro.gemspec version is #{patro_spec.version} for #{patro_version}")
assert(core_spec.runtime_dependencies.empty?, "nepdate must have no runtime dependency")
dependency = patro_spec.runtime_dependencies.find { |dep| dep.name == "nepdate" }
assert(dependency, "nepdate-patro must depend on nepdate")
assert(dependency.requirement == Gem::Requirement.new("= #{core_version}"),
  "nepdate-patro must pin nepdate = #{core_version}, got #{dependency.requirement}")

core_gem = build(CORE_GEMSPEC, "nepdate", core_version)
patro_gem = build(PATRO_GEMSPEC, "nepdate-patro", patro_version)
core_spec, core_files = package_files(core_gem)
patro_spec, patro_files = package_files(patro_gem)

assert(core_spec.name == "nepdate", "the core package is named #{core_spec.name}")
assert(patro_spec.name == "nepdate-patro", "the patro package is named #{patro_spec.name}")
assert(core_files.include?("lib/nepdate.rb"), "the core gem has no lib/nepdate.rb")
assert(core_files.any? { |file| file.start_with?("sig/") }, "the core gem has no signatures")
assert(patro_files.include?("lib/nepdate/patro.rb"), "the patro gem has no lib/nepdate/patro.rb")
assert(patro_files.any? { |file| file.start_with?("sig/") }, "the patro gem has no signatures")

forbidden = %w[test/ tests/ scripts/ shared/ bench/ docs/]
(core_files + patro_files).each do |file|
  assert(forbidden.none? { |prefix| file.start_with?(prefix) }, "#{file} must not ship in a gem")
end
assert(core_files.none? { |file| file.include?("patro") }, "the core gem contains patro files")

core_text = core_files.select { |file| file.end_with?(".rb") }.map { |file| File.read(File.join(ROOT, "packages/nepdate", file)) }.join
assert(!core_text.include?(LONG_EVENT), "the core gem carries patro event data")
patro_text = patro_files.select { |file| file.end_with?(".rb") }.map { |file| File.read(File.join(ROOT, "packages/nepdate-patro", file)) }.join
assert(patro_text.include?(LONG_EVENT), "the patro gem does not carry its event data")

Dir.mktmpdir("nepdate-install") do |install_dir|
  [core_gem, patro_gem].each do |gem_path|
    install = [
      Gem.ruby, "-S", "gem", "install", "--local", "--install-dir", install_dir,
      "--no-document", "--ignore-dependencies", gem_path
    ]
    _stdout, stderr, status = Open3.capture3(
      CLEAN_BUNDLER_ENV.merge("GEM_HOME" => install_dir, "GEM_PATH" => install_dir),
      *install
    )
    fail_with("gem install failed for #{File.basename(gem_path)}:\n#{stderr}") unless status.success?
  end

  code = <<~RUBY
    require "nepdate"
    require "nepdate/patro"
    date = NepDate::Date.parse("2081-04-15")
    raise "bad date" unless date.to_date.iso8601 == "2024-07-30"
    patro_date = NepDate::Date.parse("2081-02-15")
    raise "bad patro" unless NepDate::Patro.info(patro_date).tithi_en == "Panchami"
    puts date
  RUBY
  _stdout, stderr, status = Open3.capture3(
    CLEAN_BUNDLER_ENV.merge("GEM_HOME" => install_dir, "GEM_PATH" => install_dir),
    Gem.ruby, "-e", code
  )
  fail_with("the installed gems do not load:\n#{stderr}") unless status.success?
end

puts "release_check: #{core_version}; both gems packed and installed from dist/"
