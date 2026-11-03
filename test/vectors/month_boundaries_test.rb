# frozen_string_literal: true

require_relative "../test_helper"

# month-boundaries.csv: the first and last day of every BS month, 7176 rows. It is the
# exhaustive check of the generated month lengths and the AD conversion.
class MonthBoundariesTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("month-boundaries.csv", delimiter: ",")
    assert_equal 7176, rows.length

    rows.each do |row|
      label = "row #{row["bs"]}"
      date = NepDate::Date.parse(row["bs"])
      assert_equal row["ad"], date.to_date.iso8601, label
      assert_equal row["weekday"], date.weekday.label, label
      assert_equal row["month_length"].to_i, date.month_length, label
      assert_equal date, NepDate::Date.from_date(date.to_date), label
    end
  end
end
