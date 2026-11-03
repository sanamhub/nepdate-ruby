# frozen_string_literal: true

require_relative "../test_helper"

# spec/vectors/parse.tsv: the strict and lenient parsers, with ERR:Kind in the cells.
class ParseTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("parse.tsv")
    assert_equal 69, rows.length

    rows.each do |row|
      input = row["input"]
      Outcome.assert_matches(row["strict"], Outcome.date { NepDate::Date.parse(input) }, "strict #{input.inspect}")
      Outcome.assert_matches(
        row["lenient"],
        Outcome.date { NepDate::Date.parse_lenient(input) },
        "lenient #{input.inspect}"
      )
    end
  end

  def test_the_non_throwing_forms_leave_no_value
    assert_nil NepDate::Date.try_parse("2080/13/01")
    assert_nil NepDate::Date.try_parse_lenient("not a date")
    assert_equal "2080-05-15", NepDate::Date.try_parse("2080/05/15").iso8601
    assert_equal "2080-04-15", NepDate::Date.try_parse_lenient("15 Shrawan 2080").iso8601
  end

  def test_mixed_digits_and_a_trailing_backslash
    assert_equal "2080-05-15", NepDate::Date.parse("२०८०/05/१५").iso8601
    assert_equal "2080-05-15", NepDate::Date.parse("2080\\05\\15").iso8601
    assert_equal "2080-05-15", NepDate::Date.parse("2080।05।15").iso8601
  end

  def test_error_kinds_are_the_parsing_spec_kinds
    {
      "abc" => :invalid_character,
      "2080/05" => :wrong_group_count,
      "2080/05/15/01" => :wrong_group_count,
      "2080/05/15x" => :invalid_character,
      "12345/01/01" => :number_too_long,
      "2080/13/01" => :invalid_month,
      "2080/05/40" => :invalid_day,
      "1900/12/30" => :out_of_range
    }.each do |text, kind|
      error = assert_raises(NepDate::Error) { NepDate::Date.parse(text) }
      assert_equal kind, error.kind
    end
  end
end
