# frozen_string_literal: true

# Runs every fenced Ruby sample in README.md and docs/API.md in a fresh Ruby process. A sample
# starts from the two requires, so it is a user's example and not a fragment that only works after
# an earlier block.

require "open3"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
FILES = [
  File.join(ROOT, "README.md"),
  File.join(ROOT, "docs/API.md"),
  File.join(ROOT, "packages/nepdate/README.md"),
  File.join(ROOT, "packages/nepdate-patro/README.md")
].freeze
PRELUDE = <<~RUBY
  require "nepdate"
  require "nepdate/patro"
  require "json"
RUBY

def samples(path)
  text = File.read(path, encoding: "UTF-8")
  blocks = []
  in_block = false
  current = []
  text.each_line do |line|
    if line.start_with?("```")
      if in_block
        blocks << current.join
        current = []
        in_block = false
      else
        in_block = line.strip == "```ruby"
      end
      next
    end
    current << line if in_block
  end
  blocks
end

failures = 0
count = 0

Dir.mktmpdir("nepdate-examples") do |dir|
  FILES.each do |path|
    samples(path).each_with_index do |sample, index|
      count += 1
      file = File.join(dir, "sample_#{count}.rb")
      File.write(file, PRELUDE + sample, encoding: "UTF-8")
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        "-I", File.join(ROOT, "packages/nepdate/lib"),
        "-I", File.join(ROOT, "packages/nepdate-patro/lib"),
        file
      )
      next if status.success?

      failures += 1
      warn "FAIL: #{File.basename(path)} sample #{index + 1}"
      warn sample
      warn stdout unless stdout.empty?
      warn stderr unless stderr.empty?
    end
  end
end

if failures.positive?
  warn "#{failures} of #{count} Ruby samples failed"
  exit 1
end

puts "#{count} Ruby samples ran"
