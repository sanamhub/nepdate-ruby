# frozen_string_literal: true

require_relative "../test_helper"

class FiscalYearTest < Minitest::Test
  def test_containing_start_end_and_range
    date = NepDate::Date.parse("2081-04-15")
    fiscal = date.fiscal_year
    assert_equal 2081, fiscal.start_year
    assert_equal "2081-04-01", fiscal.start.iso8601
    assert_equal "2082-03-32", fiscal.end.iso8601
    assert_equal "2081-04-01..2082-03-32", Outcome.range_text(fiscal.range)
    assert_equal 2081, fiscal.start_year
    assert_equal 2080, NepDate::FiscalYear.containing(NepDate::Date.parse("2081-01-01")).start_year
    assert_equal "2081/82", fiscal.label
    assert_equal "२०८१/८२", fiscal.label(lang: :ne)
  end

  def test_quarters
    fiscal = NepDate::FiscalYear.new(2081)
    assert_equal "2081-04-01..2081-06-30", Outcome.range_text(fiscal.quarter_range(:q1))
    assert_equal "2081-07-01..2081-09-29", Outcome.range_text(fiscal.quarter_range(:q2))
    assert_equal "2081-10-01..2081-12-31", Outcome.range_text(fiscal.quarter_range(:q3))
    assert_equal "2082-01-01..2082-03-32", Outcome.range_text(fiscal.quarter_range(:q4))
    assert_equal "2081-04-01", fiscal.quarter_start(:q1).iso8601
    assert_equal "2082-03-32", fiscal.quarter_end(:q4).iso8601
    assert_equal NepDate::Quarter::Q1, NepDate::Date.parse("2081-04-01").quarter
    assert_equal NepDate::Quarter::Q2, NepDate::Date.parse("2081-07-01").quarter
    assert_equal NepDate::Quarter::Q3, NepDate::Date.parse("2081-10-01").quarter
    assert_equal NepDate::Quarter::Q4, NepDate::Date.parse("2081-01-01").quarter
  end

  def test_bounds
    assert_raises(NepDate::OutOfRangeError) { NepDate::FiscalYear.new(1900).start }
    assert_raises(NepDate::OutOfRangeError) { NepDate::FiscalYear.new(2199).end }
    assert_equal "1901-04-01..1902-03-31", Outcome.range_text(NepDate::FiscalYear.new(1901).range)
  end

  def test_value_equality
    assert_equal NepDate::FiscalYear.new(2081), NepDate::FiscalYear.new(2081)
    assert_equal NepDate::FiscalYear.new(2081).hash, NepDate::FiscalYear.new(2081).hash
    assert_equal NepDate::FiscalYear.new(2082), NepDate::FiscalYear.new(2081).succ
    assert_equal "2081/82", NepDate::FiscalYear.new(2081).to_s
    assert_includes NepDate::FiscalYear.new(2081).inspect, "2081"
  end
end
