# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/format-matrix.tsv (NF02, NF08, NF09): six orders crossed with six separators,
# padded and unpadded, in both languages, plus the short-buffer rows of TryFormat.
#
# Ruby strings are never too short, so NF07 has no separate buffer method. The capacity rows
# still pin the formatting rule: the same text must be produced and its length must sit on the
# correct side of the recorded capacity.
class FormatMatrixTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/format-matrix.tsv")
    assert_equal 102, rows.length

    rows.each do |row|
      date = Outcome.bs(row["bs"])
      label = "#{row["kind"]} #{row["bs"]} #{row["format"]}"

      if row["kind"] == "try_format"
        text = (row["format"] == "default") ? date.to_s : date.format(row["format"])
        capacity = row["capacity"].to_i
        if row["result"] == "ERR"
          assert_operator text.length, :>, capacity, label
        else
          assert_equal row["result"], text, label
          assert_operator text.length, :<=, capacity, label
        end
        next
      end

      assert_equal row["result"],
        date.to_short_string(
          order: Outcome.order(row["order"]),
          separator: Outcome.separator(row["separator"]),
          pad: row["pad"] == "true",
          lang: Outcome.lang(row["lang"])
        ), label
    end
  end

  def test_every_order_and_separator_appears
    rows = Vectors.load("csharp-golden/format-matrix.tsv").select { |row| row["kind"] == "short" }
    assert_equal 6, rows.map { |row| row["order"] }.uniq.length
    assert_equal 6, rows.map { |row| row["separator"] }.uniq.length
  end
end
