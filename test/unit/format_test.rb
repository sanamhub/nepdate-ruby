# frozen_string_literal: true

require_relative "../test_helper"

class FormatTest < Minitest::Test
  def test_default_short_and_long_forms
    date = NepDate::Date.parse("2081-04-15")
    assert_equal "2081/04/15", date.to_s
    assert_equal "2081-04-15", date.iso8601
    assert_equal "15-4-2081", date.to_short_string(order: :dmy, separator: :dash, pad: false)
    assert_equal "2081\\04\\15", date.to_short_string(separator: :backslash)
    assert_equal "Shrawan 15, 2081", date.to_long_string
    assert_equal "Tuesday, Shrawan 15, 2081", date.to_long_string(weekday: true)
    assert_equal "Shrawan 15", date.to_long_string(year: false)
    assert_equal "Shrawan 5", NepDate::Date.parse("2081-04-05").to_long_string(year: false, pad: false)
  end

  def test_nepali_forms
    date = NepDate::Date.parse("2081-04-15")
    assert_equal "२०८१/०४/१५", date.to_unicode_string
    assert_equal "२०८१-०४-१५", date.to_unicode_string(separator: :dash)
    assert_equal "साउन १५, २०८१", date.to_long_unicode_string
    assert_equal "मङ्गलवार, साउन १५, २०८१", date.to_long_unicode_string(weekday: true)
    assert_equal "साउन १५, २०८१", date.to_long_string(lang: :ne)
    assert_equal "साउन", date.month_enum.short_label(lang: :ne)
  end

  def test_month_and_weekday_value_objects
    assert_equal NepDate::Month::BAISHAKH, NepDate::Month.from(1)
    assert_equal NepDate::Month::CHAITRA, NepDate::Month.from(12)
    assert_equal "Baishakh", NepDate::Month::BAISHAKH.label
    assert_equal "Bai", NepDate::Month::BAISHAKH.short_label
    assert_equal "बैशाख", NepDate::Month::BAISHAKH.label(lang: :ne)
    assert_raises(NepDate::InvalidMonthError) { NepDate::Month.new(13) }
    assert_equal NepDate::Weekday::SUNDAY, NepDate::Weekday.from(0)
    assert NepDate::Weekday::SATURDAY.saturday?
    assert NepDate::Weekday::SUNDAY.sunday?
    assert_equal "Sat", NepDate::Weekday::SATURDAY.short_label
    assert_equal "शनि", NepDate::Weekday::SATURDAY.short_label(lang: :ne)
    assert_raises(ArgumentError) { NepDate::Weekday.new(7) }
    assert_equal NepDate::Quarter::Q1, NepDate::Quarter.from(:q1)
    assert_equal "Q4", NepDate::Quarter::Q4.label
    assert_raises(ArgumentError) { NepDate::Quarter.new(5) }
  end

  def test_format_option_errors
    date = NepDate::Date.parse("2081-04-15")
    assert_raises(ArgumentError) { date.to_short_string(order: :ym) }
    assert_raises(ArgumentError) { date.to_short_string(separator: :comma) }
    assert_raises(ArgumentError) { date.format("yyyy", lang: :fr) }
    assert_raises(TypeError) { date.format(:yyyy) }
  end
end
