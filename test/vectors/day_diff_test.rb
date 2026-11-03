# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/day-diff.tsv: D-07 names both directions. days_until(b) is b - a; the operator
# a - b keeps the C# sign and is positive when a is later.
class DayDiffTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/day-diff.tsv")
    assert_equal 16, rows.length

    rows.each do |row|
      first = NepDate::Date.parse(row["a"])
      second = NepDate::Date.parse(row["b"])
      assert_equal row["days_until"].to_i, first.days_until(second), "#{row["a"]} -> #{row["b"]}"
      assert_equal row["operator_minus"].to_i, first - second, "#{row["a"]} - #{row["b"]}"
    end
  end

  def test_the_breakdown_examples
    examples = [
      ["2080-01-01", "2081-04-15", 1, 1, 3, 14, 473],
      ["2081-04-15", "2080-01-01", -1, 1, 3, 14, -473],
      ["2081-04-32", "2081-05-31", 1, 0, 1, 0, 31],
      ["2081-04-32", "2081-06-01", 1, 0, 1, 1, 32],
      ["2081-01-31", "2081-02-30", 1, 0, 0, 30, 30],
      ["2081-03-15", "2081-03-15", 1, 0, 0, 0, 0]
    ]
    examples.each do |a, b, sign, years, months, days, total|
      diff = NepDate::Date.parse(a).diff(NepDate::Date.parse(b))
      assert_equal sign, diff.sign, "#{a}..#{b}"
      assert_equal years, diff.years, "#{a}..#{b}"
      assert_equal months, diff.months, "#{a}..#{b}"
      assert_equal days, diff.days, "#{a}..#{b}"
      assert_equal total, diff.total_days, "#{a}..#{b}"
    end
  end
end
