# frozen_string_literal: true

require_relative "../test_helper"

# The files and row counts this port asserts. A new shared vector must be added here, so the
# suite cannot silently stop loading a file.
class VectorsManifestTest < Minitest::Test
  EXPECTED = {
    "month-boundaries.csv" => [7176, ","],
    "parse.tsv" => [69, "\t"],
    "year-length.tsv" => [299, "\t"],
    "csharp-golden/dates.tsv" => [1018, "\t"],
    "csharp-golden/add-days.tsv" => [9162, "\t"],
    "csharp-golden/add-months.tsv" => [10_180, "\t"],
    "csharp-golden/parse.tsv" => [42, "\t"],
    "csharp-golden/format-pattern.tsv" => [452, "\t"],
    "csharp-golden/format-matrix.tsv" => [102, "\t"],
    "csharp-golden/day-diff.tsv" => [16, "\t"],
    "csharp-golden/ymd-int.tsv" => [14, "\t"],
    "csharp-golden/bulk.tsv" => [6, "\t"],
    "csharp-golden/serialization.tsv" => [11, "\t"],
    "csharp-golden/ranges.tsv" => [54, "\t"],
    "csharp-golden/range-factories.tsv" => [27, "\t"],
    "csharp-golden/range-splits.tsv" => [9, "\t"],
    "csharp-golden/range-days.tsv" => [18, "\t"],
    "csharp-golden/range-format.tsv" => [18, "\t"],
    "csharp-tests/catalog.tsv" => [542, "\t"]
  }.freeze

  def test_every_file_and_count
    EXPECTED.each do |file, (count, delimiter)|
      rows = Vectors.load(file, delimiter: delimiter)
      assert_equal count, rows.length, file
      refute_empty rows.first, file
    end
  end

  def test_the_total_is_the_expected_row_count
    total = EXPECTED.sum { |file, (count, delimiter)| Vectors.load(file, delimiter: delimiter).length }
    assert_equal 29_215, total
  end
end
