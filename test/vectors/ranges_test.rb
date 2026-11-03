# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/ranges.tsv (NR01-NR04, NR06, NR15-NR21, NR27, NR30). A range is inclusive and
# non-empty; D-01 refuses start > end and D-16 never throws at the data end.
class RangesTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/ranges.tsv")
    assert_equal 54, rows.length

    rows.each do |row|
      building = -> { NepDate::DateRange.new(Outcome.bs(row["start"]), Outcome.bs(row["end"])) }
      argument = row["argument"]
      label = "#{row["start"]}..#{row["end"]} #{row["operation"]} #{argument}"

      actual = case row["operation"]
      when "construct" then Outcome.range { building.call }
      when "length" then Outcome.scalar { building.call.length }
      when "equals" then Outcome.scalar { building.call == Outcome.parse_range(argument) }
      when "contains_date" then Outcome.scalar { building.call.include?(Outcome.bs(argument)) }
      when "contains_range" then Outcome.scalar { building.call.contains_range?(Outcome.parse_range(argument)) }
      when "overlaps" then Outcome.scalar { building.call.overlaps?(Outcome.parse_range(argument)) }
      when "is_adjacent_to" then Outcome.scalar { building.call.adjacent_to?(Outcome.parse_range(argument)) }
      when "intersect" then Outcome.range { building.call.intersect(Outcome.parse_range(argument)) }
      when "union" then Outcome.range { building.call.union(Outcome.parse_range(argument)) }
      when "except" then Outcome.range_list { building.call.except(Outcome.parse_range(argument)) }
      when "to_string" then Outcome.scalar { building.call.to_s }
      when "enumerate" then Outcome.date_list { building.call.to_a }
      else flunk("unknown operation #{row["operation"]}")
      end

      Outcome.assert_matches(row["result"], actual, label)
    end
  end

  def test_every_operation_appears
    operations = Vectors.load("csharp-golden/ranges.tsv").map { |row| row["operation"] }.uniq
    assert_equal 12, operations.length
    assert_equal 12, (operations & %w[construct length equals contains_date contains_range overlaps
      is_adjacent_to intersect union except to_string enumerate]).length
  end

  def test_a_rejected_range_is_out_of_range
    error = assert_raises(NepDate::OutOfRangeError) do
      NepDate::DateRange.new(NepDate::Date.parse("2081-04-20"), NepDate::Date.parse("2081-04-10"))
    end
    assert_equal :out_of_range, error.kind
  end

  def test_the_data_end_does_not_throw
    range = NepDate::DateRange.new(NepDate::Date.parse("2199-12-30"), NepDate::Date.parse("2199-12-30"))
    assert_equal [NepDate::Date::MAX], range.to_a
    assert_equal 1, range.length
    assert_equal false, range.adjacent_to?(
      NepDate::DateRange.new(NepDate::Date.parse("2199-12-25"), NepDate::Date.parse("2199-12-30"))
    )
  end
end
