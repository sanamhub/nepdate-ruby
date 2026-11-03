# frozen_string_literal: true

require_relative "../test_helper"

class DateTest < Minitest::Test
  def test_construction_and_validation_order
    date = NepDate::Date.new(2081, 4, 15)
    assert_equal [2081, 4, 15], date.to_a
    assert_equal [2081, 4, 15], date.deconstruct
    assert_equal({year: 2081, month: 4, day: 15}, date.to_h)

    error = assert_raises(NepDate::OutOfRangeError) { NepDate::Date.new(1900, 13, 40) }
    assert_equal :out_of_range, error.kind
    error = assert_raises(NepDate::InvalidMonthError) { NepDate::Date.new(2081, 13, 40) }
    assert_equal :invalid_month, error.kind
    error = assert_raises(NepDate::InvalidDayError) { NepDate::Date.new(2081, 4, 33) }
    assert_equal :invalid_day, error.kind
  end

  def test_accessors_and_boundaries
    date = NepDate::Date.parse("2081-04-15")
    assert_equal 2081, date.year
    assert_equal 4, date.month
    assert_equal 15, date.day
    assert_equal 109, date.day_of_year
    assert_equal 32, date.month_length
    assert_equal 366, date.year_length
    assert_equal NepDate::Month::SHRAWAN, date.month_enum
    assert_equal "Shrawan", date.month_name.label
    assert_equal NepDate::Weekday::TUESDAY, date.weekday
    assert_equal "Tuesday", date.weekday.label
    assert_equal NepDate::Date.parse("2081-04-32"), date.last_day_of_month
  end

  def test_comparison_equality_and_hashing
    one = NepDate::Date.parse("2081-04-15")
    two = NepDate::Date.parse("2081-04-16")
    same = NepDate::Date.parse("2081-04-15")
    assert_equal(-1, one <=> two)
    assert_equal 1, two <=> one
    assert_equal 0, one <=> same
    assert_nil one <=> "2081-04-15"
    assert one < two
    assert two > one
    assert one == same
    assert one.eql?(same)
    assert_equal one.hash, same.hash
    assert_equal 0, one.compare_to(same)
  end

  def test_date_and_time_interop
    date = NepDate::Date.parse("2081-04-15")
    assert_equal "2024-07-30", date.to_date.iso8601
    assert_equal date, NepDate::Date.from_date(::Date.new(2024, 7, 30))
    assert_equal date, NepDate::Date.from_time(Time.utc(2024, 7, 30, 23, 59, 59))
    assert_equal "2024-07-30", NepDate::Date.from_gregorian(2024, 7, 30).to_date.iso8601
    assert_equal 20_700, date.to_time.utc_offset
    assert_equal 20_700, date.to_datetime.offset * 86_400
    assert_raises(NepDate::InvalidGregorianError) { NepDate::Date.from_gregorian(2023, 2, 29) }
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date.from_gregorian(1844, 4, 10) }
  end

  def test_succ_and_ruby_ranges
    first = NepDate::Date.parse("2081-04-15")
    assert_equal "2081-04-16", first.succ.iso8601
    assert_equal %w[2081-04-15 2081-04-16 2081-04-17], (first..first.add_days(2)).map(&:iso8601)
  end

  def test_pattern_matching
    case NepDate::Date.parse("2081-04-15")
    in {year: 2081, month: 4, day: 15}
      assert true
    else
      flunk "deconstruct_keys did not match"
    end

    case NepDate::Date.parse("2081-04-15")
    in [2081, 4, 15]
      assert true
    else
      flunk "deconstruct did not match"
    end
  end

  def test_inspect_and_string_forms
    date = NepDate::Date.parse("2081-04-15")
    assert_equal "#<NepDate::Date 2081-04-15>", date.inspect
    assert_equal "2081/04/15", date.to_s
    assert_equal "2081-04-15", date.iso8601
    assert_equal "2081-04-15", date.isoformat
    assert_equal 20_810_415, date.to_ymd
  end
end
