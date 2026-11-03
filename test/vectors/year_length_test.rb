# frozen_string_literal: true

require_relative "../test_helper"

# year-length.tsv is the D-12 reference vector: the BS year length, 364 to 367.
class YearLengthTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("year-length.tsv")
    assert_equal 299, rows.length

    rows.each do |row|
      year = row["bs_year"].to_i
      date = NepDate::Date.from_bs(year, 1, 1)
      assert_equal row["year_length"].to_i, date.year_length, "year #{year}"
      assert_includes 364..367, date.year_length
    end
  end

  def test_length_is_the_sum_of_the_twelve_months
    (1901..2199).each do |year|
      date = NepDate::Date.from_bs(year, 1, 1)
      total = (1..12).sum { |month| NepDate::Date.from_bs(year, month, 1).month_length }
      assert_equal total, date.year_length, "year #{year}"
    end
  end
end
