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

  def test_language_and_overflow_coercion_accept_both_spellings
    assert_equal :en, NepDate::Lang.coerce("en")
    assert_equal :ne, NepDate::Lang.coerce("ne")
    assert_raises(ArgumentError) { NepDate::Lang.coerce(:fr) }
    assert_equal :clamp, NepDate::MonthOverflow.coerce(:clamp)
    assert_equal :spill, NepDate::MonthOverflow.coerce(:spill)
    assert_equal :clamp, NepDate::MonthOverflow.coerce("clamp")
    assert_raises(ArgumentError) { NepDate::MonthOverflow.coerce(:other) }
  end

  def test_formatting_in_nepali_and_without_a_weekday
    date = NepDate::Date.parse("2081-04-15")
    assert_equal "२०८१/०४/१५", date.format("", lang: :ne)
    assert_equal "२०८१-०४-१५", date.format("s", lang: :ne)
    assert_equal "Shrawan 15, 2081", date.to_long_string
    assert_equal "आइतवार", NepDate::Names.weekday_name(0, :ne)
    assert_equal "००५", NepDate::Names.digits(5, :ne, width: 3)
    assert_equal "123", NepDate::Names.digits(123)
    assert_equal "१२३", NepDate::Names.digits(123, :ne)
  end

  def test_parse_accepts_the_danda_and_rejects_a_bad_ten_byte_separator
    assert_equal "2081-04-15", NepDate::Date.parse("२०८१।०४।१५").iso8601
    assert_raises(NepDate::ParseError) { NepDate::Date.parse("2081x04x15") }
  end

  def test_batch_accepts_every_gregorian_value_and_today_reads_the_clock
    dates = [
      NepDate::Date.parse("2081-04-15"),
      Time.utc(2024, 7, 30, 12),
      DateTime.new(2024, 7, 30, 12),
      ::Date.new(2024, 7, 30)
    ]
    converted = NepDate::Date.from_gregorian_batch(dates)
    assert_equal ["2081-04-15"] * 4, converted.map(&:iso8601)

    assert_instance_of NepDate::Date, NepDate::Date.today(zone: "UTC")
    assert_equal "2024-01-15", NepDate::Date.from_gregorian(2024, 1, 15).to_date.iso8601
    assert_equal "2024-02-29", NepDate::Date.from_gregorian(2024, 2, 29).to_date.iso8601
  end

  def test_patro_info_rejects_a_non_date_and_returns_the_empty_value_outside_coverage
    assert_raises(TypeError) { NepDate::Patro.info("2081-04-15") }
    empty = NepDate::Patro.info(NepDate::Date.parse("2070-06-15"))
    assert_equal "", empty.tithi_np
    assert_equal "", empty.tithi_en
    assert_equal [], empty.events_np
    assert_equal [], empty.events_en
    assert_equal({tithi: nil, public_holiday: false, events: []}, empty.to_h)
    assert_includes empty.inspect, "tithi=nil"
  end
end
