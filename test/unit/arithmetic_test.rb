# frozen_string_literal: true

require_relative "../test_helper"

class ArithmeticTest < Minitest::Test
  def test_add_days_and_month_overflow
    date = NepDate::Date.parse("2081-04-32")
    assert_equal "2081-05-01", date.add_days(1).iso8601
    assert_equal "2081-06-30", date.add_months(2).iso8601
    assert_equal "2081-07-02", date.add_months(2, overflow: :spill).iso8601
    assert_raises(ArgumentError) { date.add_months(2, overflow: :round) }
    assert_raises(TypeError) { date.add_days(1.5) }
  end

  def test_operator_directions
    early = NepDate::Date.parse("2080-01-01")
    late = NepDate::Date.parse("2081-04-15")
    assert_equal 473, early.days_until(late)
    assert_equal(-473, late.days_until(early))
    assert_equal 473, late - early
    assert_equal(-473, early - late)
    assert_equal "2080-01-02", (early + 1).iso8601
    assert_equal "2079-12-30", (early - 1).iso8601
    assert_raises(TypeError) { early - "2080-01-01" }
    assert_raises(TypeError) { early + "one" }
  end

  def test_diff_is_signed_and_symmetric_in_its_parts
    early = NepDate::Date.parse("2080-01-01")
    late = NepDate::Date.parse("2081-04-15")
    forward = early.diff(late)
    backward = late.diff(early)
    assert_equal [1, 3, 14, 473], [forward.years, forward.months, forward.days, forward.total_days]
    refute forward.negative?
    assert backward.negative?
    assert_equal [1, 3, 14, -473], [backward.years, backward.months, backward.days, backward.total_days]
    assert_equal(-1, backward.sign)
    assert_equal forward.to_h, forward.to_h
    assert_equal forward, early.calendar_breakdown(late)
  end

  def test_month_and_year_addition_are_consistent
    date = NepDate::Date.parse("2081-04-15")
    assert_equal date.add_months(24), date.add_years(2)
    assert_equal date.add_months(-24), date.add_years(-2)
    assert_equal date, date.add_years(0)
  end
end
