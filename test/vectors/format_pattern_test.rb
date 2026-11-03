# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/format-pattern.tsv (NF06): 452 rows of the custom pattern language.
# The two D-04 rows, Ashad and Ashoj abbreviated as MMM, are asserted separately below.
class FormatPatternTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/format-pattern.tsv")
    assert_equal 452, rows.length

    rows.each do |row|
      date = NepDate::Date.parse(row["bs"])
      next if d04_row?(date, row["pattern"])

      assert_equal row["result"], date.format(row["pattern"]), "#{row["bs"]} #{row["pattern"].inspect}"
    end
  end

  def test_the_two_abbreviations_follow_d04
    assert_equal "Asa", NepDate::Date.parse("2081-03-01").format("MMM")
    assert_equal "Aso", NepDate::Date.parse("2081-06-01").format("MMM")
    assert_equal "Ashad", NepDate::Date.parse("2081-03-01").format("MMMM")
    assert_equal "Ashoj", NepDate::Date.parse("2081-06-01").format("MMMM")
    assert_equal "असार", NepDate::Date.parse("2081-03-01").format("MMM", lang: :ne)
  end

  def test_the_standard_patterns
    date = NepDate::Date.parse("2081-04-15")
    assert_equal "2081/04/15", date.format("")
    assert_equal "2081/04/15", date.format("G")
    assert_equal "2081/04/15", date.format("g")
    assert_equal "2081/04/15", date.format("d")
    assert_equal "Shrawan 15, 2081", date.format("D")
    assert_equal "2081-04-15", date.format("s")
  end

  def test_escapes_quotes_and_a_trailing_backslash
    date = NepDate::Date.parse("2081-04-15")
    assert_equal "2081BS", date.format("yyyy'BS'")
    assert_equal "2081MM-dd", date.format("yyyy\\M\\M-\\d\\d")
    assert_equal "Shr 2081", date.format("MMM yyyy")
    assert_equal "15.04.81", date.format("dd.MM.yy")
    assert_equal "\\", date.format("\\")
    assert_equal "abc", date.format("'abc'")
    assert_equal "abc", date.format("'abc")
  end

  private

  def d04_row?(date, pattern)
    pattern.include?("MMM") && !pattern.include?("MMMM") && [3, 6].include?(date.month)
  end
end
