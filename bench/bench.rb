# frozen_string_literal: true

# B1 to B8 of shared/spec/BENCHMARK.md: the 64 core dates, the 64 patro dates and a manual
# monotonic-clock harness. Ruby has no reliable per-operation byte allocator, so bytes are reported
# as "not measured", which the benchmark spec allows for a dynamic language.
#
#   ruby -Ipackages/nepdate/lib -Ipackages/nepdate-patro/lib bench/bench.rb
#
# Every result is written to bench/results/<date>.json and printed as a table.

require "json"
require "time"
require "nepdate"
require "nepdate/patro"

module Bench
  CORE_START = NepDate::Date.from_bs(2000, 1, 1).serial
  CORE_END = NepDate::Date.from_bs(2090, 12, 30).serial
  STEP = (CORE_END - CORE_START) / 63
  COVERAGE = NepDate::Patro.coverage
  PATRO_STEP = (COVERAGE.end.serial - COVERAGE.start.serial) / 63

  module_function

  def core_dates
    (0..63).map { |index| NepDate::Date.from_serial(CORE_START + index * STEP) }
  end

  def patro_dates
    (0..63).map { |index| NepDate::Date.from_serial(COVERAGE.start.serial + index * PATRO_STEP) }
  end

  def clock
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def measure(name)
    yield # warm-up
    iterations = 1
    loop do
      started = clock
      iterations.times { yield }
      elapsed = clock - started
      break if elapsed >= 0.15 || iterations >= 1_048_576

      iterations *= 2
    end

    samples = Array.new(10) do
      started = clock
      iterations.times { yield }
      (clock - started) / (iterations * 64.0) * 1_000_000_000
    end
    mean = samples.sum / samples.length
    variance = samples.sum { |sample| (sample - mean)**2 } / (samples.length - 1)
    [mean, Math.sqrt(variance), iterations]
  end

  def run
    dates = core_dates
    patro_inputs = patro_dates
    patro_ranges = patro_inputs.map { |date| NepDate::DateRange.for_month(date.year, date.month) }
    texts = dates.map(&:to_s)
    ad_dates = dates.map(&:to_date)
    operations = {
      "B1" => "BS to AD",
      "B2" => "AD to BS",
      "B3" => "add 1000 days",
      "B4" => "add 13 months, Clamp",
      "B5" => "long format, Nepali, weekday",
      "B6" => "strict parse YYYY/MM/DD",
      "B7" => "patro info",
      "B8" => "patro month grid"
    }

    measurements = {}
    operations.each_key do |name|
      block = case name
      when "B1"
        -> { dates.each { |date| date.to_date.jd } }
      when "B2"
        -> { ad_dates.each { |date| NepDate::Date.from_date(date).serial } }
      when "B3"
        -> { dates.each { |date| date.add_days(1000).serial } }
      when "B4"
        -> { dates.each { |date| date.add_months(13).serial } }
      when "B5"
        -> { dates.each { |date| date.to_long_string(weekday: true, lang: :ne).bytesize } }
      when "B6"
        -> { texts.each { |text| NepDate::Date.parse(text).serial } }
      when "B7"
        -> { patro_inputs.each { |date| info_size(NepDate::Patro.info(date)) } }
      when "B8"
        -> do
          patro_ranges.sum do |range|
            range.sum { |date| info_size(NepDate::Patro.info(date)) }
          end
        end
      end

      mean, stddev, iterations = measure(name, &block)
      measurements[name] = {
        "operation" => operations.fetch(name),
        "ns_per_operation" => mean.round(1),
        "stddev_ns" => stddev.round(1),
        "iterations" => iterations,
        "bytes_per_operation" => nil
      }
      puts format("%-2s %-34s %10.1f ns/op  sd %8.1f", name, operations.fetch(name), mean, stddev)
    end

    {
      "date" => Time.now.utc.iso8601,
      "ruby" => RUBY_DESCRIPTION,
      "ruby_version" => RUBY_VERSION,
      "platform" => RUBY_PLATFORM,
      "inputs" => 64,
      "warmup" => "one pass, then a pass of at least 0.15 s",
      "samples" => 10,
      "measurement" => "manual monotonic clock; one iteration is all 64 inputs; B8 is one month grid per input",
      "bytes" => "not measured; Ruby has no reliable per-operation byte allocator",
      "operations" => measurements
    }
  end

  def info_size(info)
    size = info.events.length
    size += 1 if info.tithi
    size += 1 if info.public_holiday?
    size
  end
end

if $PROGRAM_NAME == __FILE__
  result = Bench.run
  directory = File.expand_path("results", __dir__)
  require "fileutils"
  FileUtils.mkdir_p(directory)
  path = File.join(directory, "#{Time.now.utc.strftime("%Y-%m-%d")}.json")
  File.write(path, JSON.pretty_generate(result) + "\n", encoding: "UTF-8")
  puts "wrote #{path}"
end
