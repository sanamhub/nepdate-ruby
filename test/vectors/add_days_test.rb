# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/add-days.tsv, 9162 rows: integer day arithmetic and its boundaries.
class AddDaysTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/add-days.tsv")
    assert_equal 9162, rows.length

    rows.each do |row|
      date = NepDate::Date.parse(row["bs"])
      days = row["days"].to_i
      Outcome.assert_matches(row["result"], Outcome.date { date.add_days(days) }, "#{row["bs"]} #{days}")
    end
  end

  def test_the_maximum_offsets_do_not_wrap
    assert_equal NepDate::Date::MAX, NepDate::Date::MIN.add_days(109_211)
    assert_equal NepDate::Date::MIN, NepDate::Date::MAX.add_days(-109_211)
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date::MIN.add_days(-1) }
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date::MAX.add_days(1) }
  end
end
