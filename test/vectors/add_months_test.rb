# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/add-months.tsv, 10180 rows: whole-month arithmetic with clamp and spill.
class AddMonthsTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/add-months.tsv")
    assert_equal 10_180, rows.length

    rows.each do |row|
      date = NepDate::Date.parse(row["bs"])
      months = row["months"].to_i
      label = "#{row["bs"]} #{months}"
      Outcome.assert_matches(row["clamp"], Outcome.date { date.add_months(months) }, label)
      Outcome.assert_matches(
        row["overflow"],
        Outcome.date { date.add_months(months, overflow: :spill) },
        label
      )
    end
  end

  def test_the_algorithm_examples
    date = NepDate::Date.parse("2081-04-32")
    assert_equal "2081-06-30", date.add_months(2).iso8601
    assert_equal "2081-07-02", date.add_months(2, overflow: :spill).iso8601
    assert_equal "2081-09-29", date.add_months(5).iso8601
    assert_equal "2081-10-03", date.add_months(5, overflow: :spill).iso8601
  end

  def test_extreme_offsets_do_not_wrap
    assert_equal "1901-01-01", NepDate::Date::MIN.add_months(0).iso8601
    assert_equal "2199-12-30", NepDate::Date::MAX.add_months(0).iso8601
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date::MIN.add_months(-1) }
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date::MAX.add_months(1) }
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date::MAX.add_months(1, overflow: :spill) }
  end

  def test_add_years_uses_twelve_months
    date = NepDate::Date.parse("2081-04-32")
    assert_equal date.add_months(24).iso8601, date.add_years(2).iso8601
    assert_equal date.add_months(24, overflow: :spill).iso8601,
      date.add_years(2, overflow: :spill).iso8601
  end
end
