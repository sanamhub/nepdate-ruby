# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/dates.tsv: weekday, day of year, month length, every string form and the
# fiscal-year and quarter boundaries, for 1018 dates across the whole range.
class DatesTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/dates.tsv")
    assert_equal 1018, rows.length

    rows.each do |row|
      label = "row #{row["bs"]}"
      date = NepDate::Date.parse(row["bs"])
      assert_equal row["bs"], date.iso8601, label
      assert_equal row["ad"], date.to_date.iso8601, label
      assert_equal row["weekday"], date.weekday.label, label
      assert_equal row["day_of_year"].to_i, date.day_of_year, label
      assert_equal row["month_length"].to_i, date.month_length, label
      assert_equal row["to_string"], date.to_s, label
      assert_equal row["unicode"], date.to_short_string(lang: :ne), label
      assert_equal row["long_en"], date.to_long_string, label
      assert_equal row["long_en_weekday"], date.to_long_string(weekday: true), label
      assert_equal row["long_ne"], date.to_long_string(lang: :ne), label
      assert_equal row["long_ne_weekday"], date.to_long_string(weekday: true, lang: :ne), label
      assert_equal row["dmy_dash_nopad"], date.to_short_string(order: :dmy, separator: :dash, pad: false), label

      Outcome.assert_matches(row["fy_start"], Outcome.date { date.fiscal_year.start }, label)
      Outcome.assert_matches(row["fy_end"], Outcome.date { date.fiscal_year.end }, label)
      Outcome.assert_matches(
        row["quarter_start"],
        Outcome.date { date.fiscal_year.quarter_range(date.quarter).start },
        label
      )
      Outcome.assert_matches(
        row["quarter_end"],
        Outcome.date { date.fiscal_year.quarter_range(date.quarter).end },
        label
      )
    end
  end

  def test_boundaries
    assert_equal "1901-01-01", NepDate::Date::MIN.iso8601
    assert_equal "1844-04-11", NepDate::Date::MIN.to_date.iso8601
    assert_equal "2199-12-30", NepDate::Date::MAX.iso8601
    assert_equal "2143-04-15", NepDate::Date::MAX.to_date.iso8601
    assert_equal "Thursday", NepDate::Date::MIN.weekday.label
  end
end
