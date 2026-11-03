# frozen_string_literal: true

require_relative "../test_helper"

# The small branches that the vector files do not reach: value-object coercion, public argument
# types, the maximum-day spill and the direct separator form.
class EdgesTest < Minitest::Test
  def test_calendar_rejects_an_invalid_month_and_gregorian_date
    assert_raises(NepDate::InvalidMonthError) { NepDate::Calendar.month_length(2081, 13) }
    refute NepDate::Calendar.valid_gregorian?(2024, 13, 1)
    refute NepDate::Calendar.valid_gregorian?(2023, 2, 29)
    assert NepDate::Calendar.valid_gregorian?(2024, 2, 29)
    assert_raises(NepDate::OutOfRangeError) { NepDate::Calendar.month_length(1900, 1) }
  end

  def test_batch_and_converter_type_errors
    assert_raises(ArgumentError) { NepDate::Date.from_date("2024-07-30") }
    assert_raises(ArgumentError) { NepDate::Date.from_time("2024-07-30") }
    assert_raises(ArgumentError) { NepDate::Date.from_gregorian_batch(["2024-07-30"]) }
    assert_raises(TypeError) { NepDate::Date.today(zone: "+05:45", clock: -> { 42 }) }
    assert_raises(TypeError) { NepDate::Parse.strict(42) }
    assert_raises(TypeError) { NepDate::Date.from_ymd("20810415") }
  end

  def test_offset_objects_and_offsets
    assert_equal 7_200, NepDate::Date.offset_seconds(Struct.new(:utc_offset).new(7_200))
    assert_equal 0, NepDate::Date.offset_seconds("Z")
    assert_equal 20_700, NepDate::Date.offset_seconds(nil)
    assert_raises(ArgumentError) { NepDate::Date.offset_seconds("+5:45") }
    assert_raises(ArgumentError) { NepDate::Date.offset_seconds(Object.new) }
  end

  def test_spill_at_the_last_month
    date = NepDate::Date.from_bs(2199, 4, 31)
    error = assert_raises(NepDate::OutOfRangeError) { date.add_months(8, overflow: :spill) }
    assert_equal :out_of_range, error.kind
  end

  def test_value_object_coercion_and_comparison
    month = NepDate::Month::BAISHAKH
    assert_same month, NepDate::Month.from(month)
    assert_nil month <=> 1
    weekday = NepDate::Weekday::MONDAY
    assert_same weekday, NepDate::Weekday.from(weekday)
    assert_nil weekday <=> 1
    quarter = NepDate::Quarter::Q1
    assert_same quarter, NepDate::Quarter.from(quarter)
    assert_same quarter, NepDate::Quarter.from("q1")
    assert_same quarter, NepDate::Quarter.from(1)
    assert_nil quarter <=> 1
    fiscal = NepDate::FiscalYear.new(2081)
    assert_same fiscal, NepDate::FiscalYear.from(fiscal)
    assert_nil fiscal <=> 1
  end

  def test_separator_character_form
    date = NepDate::Date.parse("2081-04-15")
    assert_equal "2081.04.15", date.to_short_string(separator: ".")
    assert_equal :slash, NepDate::Separator.coerce("/")
    assert_equal :space, NepDate::Separator.coerce("space")
    assert_raises(ArgumentError) { NepDate::Separator.character(":") }
  end

  def test_range_first_last_with_a_count
    range = NepDate::DateRange.new(NepDate::Date.parse("2081-04-10"), NepDate::Date.parse("2081-04-20"))
    assert_equal range.start, range.first
    assert_equal range.end, range.last
    assert_equal 2, range.first(2).length
    assert_equal 2, range.last(2).length
    assert_raises(TypeError) { NepDate::DateRange.new(range.start, "2081-04-20") }
  end

  def test_inspect_for_both_diff_signs
    early = NepDate::Date.parse("2080-01-01")
    late = NepDate::Date.parse("2081-04-15")
    assert_includes early.diff(late).inspect, "+"
    assert_includes late.diff(early).inspect, "-"
    assert_equal early.diff(late), early.diff(late)
    assert_equal early.diff(late).hash, early.diff(late).hash
    refute early.diff(late) == "diff"
  end

  def test_lenient_odd_numeric_chunks_and_day_lengths
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("2080..05.15.99") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("2080 Shrawan 123") }
  end
end
