# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/range-splits.tsv (NR22, NR23): month and fiscal-quarter splits, clipped at the
# range ends and never throwing at 2199-12-30 (D-16).
class RangeSplitsTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/range-splits.tsv")
    assert_equal 9, rows.length

    rows.each do |row|
      range = -> { NepDate::DateRange.new(Outcome.bs(row["start"]), Outcome.bs(row["end"])) }
      label = "#{row["start"]}..#{row["end"]} #{row["operation"]}"
      actual = case row["operation"]
      when "split_by_month" then Outcome.range_list { range.call.split_by_month }
      when "split_by_fiscal_quarter" then Outcome.range_list { range.call.split_by_fiscal_quarter }
      else flunk("unknown operation #{row["operation"]}")
      end
      Outcome.assert_matches(row["result"], actual, label)
    end
  end

  def test_pieces_are_contiguous_and_cover_the_range
    range = NepDate::DateRange.new(NepDate::Date.parse("2081-01-01"), NepDate::Date.parse("2081-12-31"))
    [range.split_by_month, range.split_by_fiscal_quarter].each do |pieces|
      assert_equal range.start, pieces.first.start
      assert_equal range.end, pieces.last.end
      assert_equal range.length, pieces.sum(&:length)
      pieces.each_cons(2) { |left, right| assert left.adjacent_to?(right) }
    end
  end

  def test_a_range_at_the_data_end_is_split_without_an_extra_step
    range = NepDate::DateRange.new(NepDate::Date.parse("2199-11-30"), NepDate::Date::MAX)
    pieces = range.split_by_month
    assert_equal 2, pieces.length
    assert_equal NepDate::Date::MAX, pieces.last.end
    quarters = NepDate::DateRange.new(NepDate::Date.parse("2199-12-25"), NepDate::Date::MAX)
      .split_by_fiscal_quarter
    assert_equal 1, quarters.length
    assert_equal NepDate::Date::MAX, quarters.first.end
  end
end
