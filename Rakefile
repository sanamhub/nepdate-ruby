# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |task|
  task.libs = ["packages/nepdate/lib", "packages/nepdate-patro/lib", "test"]
  task.pattern = "test/**/*_test.rb"
  task.description = "Run the unit and shared-vector tests with coverage"
end

desc "Regenerate the calendar and patro tables"
task :generate do
  sh "ruby scripts/generate_tables.rb"
  sh "ruby scripts/generate_patro_tables.rb"
end

namespace :generate do
  desc "Fail when a generated table differs from shared data"
  task :check do
    sh "ruby scripts/generate_tables.rb --check"
    sh "ruby scripts/generate_patro_tables.rb --check"
  end
end

desc "Check formatting and lint with standard"
task :lint do
  sh "bundle exec standardrb"
end

desc "Fix formatting and lint with standard"
task :format do
  sh "bundle exec standardrb --fix"
end

desc "Validate the RBS signatures and run the public API under rbs test"
task :rbs do
  sh "bundle exec rbs -r date -r json -I packages/nepdate/sig -I packages/nepdate-patro/sig validate"
  sh "bundle exec rbs -r date -r json -I packages/nepdate/sig -I packages/nepdate-patro/sig " \
     "test --target 'NepDate::*' --sample-size 1 ruby -Ipackages/nepdate/lib " \
     "-Ipackages/nepdate-patro/lib test/rbs/smoke.rb"
end

desc "Build the YARD documentation to check it"
task :docs do
  sh "bundle exec yardoc"
end

desc "Run every Ruby sample in the README and docs/API.md"
task :examples do
  sh "bundle exec ruby scripts/check_examples.rb"
end

desc "Check versions, changelog, gems and package contents without publishing"
task :release do
  sh "bundle exec ruby scripts/release_check.rb --draft"
end

desc "Everything CI runs, in the same order"
task ci: %i[generate:check lint rbs docs examples test release]

task default: :test
