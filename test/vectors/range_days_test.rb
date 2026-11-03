# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/range-days.tsv (NR24-NR27): interval, working-day and weekend-day helpers and
# the enumerator, including the D-16 rows that reach 2199-12-30.
class RangeDaysTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/range-days.tsv")
    assert_equal 18, rows.length

    rows.each do |row|
      range = -> { NepDate::DateRange.new(Outcome.bs(row["start"]), Outcome.bs(row["end"])) }
      label = "#{row["start"]}..#{row["end"]} #{row["operation"]} #{row["argument"]}"
      actual = case row["operation"]
      when "dates_with_interval"
        Outcome.date_list { range.call.dates_with_interval(row["argument"].to_i) }
      when "working_days"
        Outcome.date_list { range.call.working_days(exclude_sunday: row["argument"] == "true") }
      when "weekend_days"
        Outcome.date_list { range.call.weekend_days(include_sunday: row["argument"] == "true") }
      when "enumerate"
        Outcome.date_list { range.call.to_a }
      else
        flunk("unknown operation #{row["operation"]}")
      end
      Outcome.assert_matches(row["result"], actual, label)
    end
  end

  def test_defaults_match_the_csharp_defaults
    range = NepDate::DateRange.new(NepDate::Date.parse("2081-04-13"), NepDate::Date.parse("2081-04-21"))
    assert_equal range.working_days(exclude_sunday: true).map(&:iso8601),
      range.working_days.map(&:iso8601) - ["2081-04-13", "2081-04-20"]
    assert_equal range.weekend_days.map(&:iso8601), range.weekend_days(include_sunday: true).map(&:iso8601)
    assert_equal range.dates_with_interval.map(&:iso8601), range.dates_with_interval(1).map(&:iso8601)
  end

  def test_a_huge_step_stops_before_the_end_does_not_overflow
    range = NepDate::DateRange.new(NepDate::Date.parse("2199-12-25"), NepDate::Date::MAX)
    assert_equal ["2199-12-25"], range.dates_with_interval(10**30).map(&:iso8601)
    assert_equal [NepDate::Date::MAX], NepDate::DateRange.single_day(NepDate::Date::MAX).dates_with_interval(10**30)
  end
end
