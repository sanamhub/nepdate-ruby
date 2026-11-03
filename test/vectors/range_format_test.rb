# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/range-format.tsv (NR28, NR29): the default and short range strings.
class RangeFormatTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/range-format.tsv")
    assert_equal 18, rows.length

    rows.each do |row|
      range = -> { NepDate::DateRange.new(Outcome.bs(row["start"]), Outcome.bs(row["end"])) }
      label = "#{row["start"]}..#{row["end"]} #{row["kind"]}"
      if row["kind"] == "default"
        Outcome.assert_matches(row["result"], Outcome.scalar { range.call.to_s }, label)
      else
        Outcome.assert_matches(
          row["result"],
          Outcome.scalar do
            range.call.to_short_string(
              order: Outcome.order(row["order"]),
              separator: Outcome.separator(row["separator"]),
              lang: Outcome.lang(row["lang"])
            )
          end,
          label
        )
      end
    end
  end

  def test_defaults_are_the_csharp_order_and_separator
    range = NepDate::DateRange.new(NepDate::Date.parse("2081-04-10"), NepDate::Date.parse("2081-04-20"))
    assert_equal "2081/04/10 - 2081/04/20", range.to_short_string
    assert_equal range.to_s, range.to_short_string
  end
end
