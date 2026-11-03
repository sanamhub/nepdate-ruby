# frozen_string_literal: true

# Turns a call into the text a golden vector records: a BS date, a start..end range, a
# semicolon-separated list, `none`, or ERR/ERR:Kind.
module Outcome
  module_function

  def date
    value = yield
    return "unexpected #{value.class}" unless value.is_a?(NepDate::Date)

    value.iso8601
  rescue NepDate::Error => e
    "ERR:#{e.kind_name}"
  end

  def range
    value = yield
    return "none" if value.nil?
    return "unexpected #{value.class}" unless value.is_a?(NepDate::DateRange)

    range_text(value)
  rescue NepDate::Error => e
    "ERR:#{e.kind_name}"
  end

  def date_list
    value = yield
    parts = value.map do |date|
      return "unexpected #{date.class}" unless date.is_a?(NepDate::Date)

      date.iso8601
    end
    parts.empty? ? "none" : parts.join(";")
  rescue NepDate::Error => e
    "ERR:#{e.kind_name}"
  end

  def range_list
    value = yield
    parts = value.map do |range|
      return "unexpected #{range.class}" unless range.is_a?(NepDate::DateRange)

      range_text(range)
    end
    parts.empty? ? "none" : parts.join(";")
  rescue NepDate::Error => e
    "ERR:#{e.kind_name}"
  end

  def scalar
    value = yield
    case value
    when true then "true"
    when false then "false"
    when Integer, String then value.to_s
    else "unexpected #{value.class}"
    end
  rescue NepDate::Error => e
    "ERR:#{e.kind_name}"
  end

  def range_text(range)
    "#{range.start.iso8601}..#{range.end.iso8601}"
  end

  def bs(text)
    NepDate::Date.parse(text)
  end

  def parse_range(text)
    first, last = Vectors.range(text)
    NepDate::DateRange.new(bs(first), bs(last))
  end

  def lang(code)
    (code == "ne") ? :ne : :en
  end

  def order(name)
    {
      "Ymd" => :ymd, "Ydm" => :ydm, "Myd" => :myd,
      "Mdy" => :mdy, "Dym" => :dym, "Dmy" => :dmy
    }.fetch(name) { raise "unknown order #{name}" }
  end

  def separator(name)
    {
      "Slash" => :slash, "Backslash" => :backslash, "Dot" => :dot,
      "Underscore" => :underscore, "Dash" => :dash, "Space" => :space
    }.fetch(name) { raise "unknown separator #{name}" }
  end

  def assert_matches(expected, actual, reason = "")
    if expected == "ERR"
      unless actual == "ERR" || actual.start_with?("ERR:")
        raise Minitest::Assertion, "expected any error, got #{actual.inspect}. #{reason}"
      end
      return
    end

    unless expected == actual
      raise Minitest::Assertion, "expected #{expected.inspect}, got #{actual.inspect}. #{reason}"
    end
  end
end
