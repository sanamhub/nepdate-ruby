# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  skip "/test/"
  skip "/scripts/"
  skip "/bench/"
  minimum_coverage line: 90, branch: 90
end

$LOAD_PATH.unshift File.expand_path("../packages/nepdate/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../packages/nepdate-patro/lib", __dir__)

require "minitest/autorun"
require "nepdate"
require "nepdate/patro"

require_relative "support/vectors"
require_relative "support/outcome"
