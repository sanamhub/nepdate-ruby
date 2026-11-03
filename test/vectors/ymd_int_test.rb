# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/ymd-int.tsv (NC09, D-11): the YYYYMMDD integer both ways.
class YmdIntTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/ymd-int.tsv")
    assert_equal 14, rows.length

    rows.each do |row|
      if row["kind"] == "date"
        date = NepDate::Date.parse(row["input"])
        assert_equal row["ymd"].to_i, date.to_ymd, row["input"]
        assert_equal row["result"], Outcome.date { NepDate::Date.from_ymd(row["ymd"].to_i) }, row["input"]
      else
        ymd = row["ymd"].to_i
        Outcome.assert_matches(row["result"], Outcome.date { NepDate::Date.from_ymd(ymd) }, row["input"])
      end
    end
  end

  def test_the_integer_does_not_wrap
    assert_equal "1901-01-01", NepDate::Date.from_ymd(19_010_101).iso8601
    assert_equal "2199-12-30", NepDate::Date.from_ymd(21_991_230).iso8601
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date.from_ymd(120_810_415) }
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date.from_ymd(-20_810_415) }
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date.from_ymd(2200_01_01) }
  end

  def test_every_first_of_month_round_trips
    (1901..2199).step(7).each do |year|
      (1..12).each do |month|
        date = NepDate::Date.from_bs(year, month, 1)
        assert_equal date, NepDate::Date.from_ymd(date.to_ymd)
      end
    end
  end
end
