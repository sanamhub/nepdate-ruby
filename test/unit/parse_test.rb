# frozen_string_literal: true

require_relative "../test_helper"

class ParseTest < Minitest::Test
  def test_strict_separators_and_group_rules
    accepted = [
      "2080/05/15", "2080-05-15", "2080.05.15", "2080_05_15", "2080 05 15",
      "2080|05|15", "2080\\05\\15", "2080।05।15", "  2080 / 05 / 15  ", "/2080/05/15/",
      "२०८०/०५/१५", "2080/०5/1५"
    ]
    accepted.each { |text| assert_equal "2080-05-15", NepDate::Date.parse(text).iso8601, text }

    assert_raises(NepDate::ParseError) { NepDate::Date.parse("") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse("2080/05") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse("2080/05/15/01") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse("12345/01/01") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse("2080-05-15T00:00") }
  end

  def test_lenient_month_forms_and_numeric_forms
    {
      "15 Shrawan 2080" => "2080-04-15",
      "Shrawan 15, 2080" => "2080-04-15",
      "2080 Shrawan 15" => "2080-04-15",
      "15/05/2080" => "2080-05-15",
      "2080/05/15" => "2080-05-15",
      "15 साउन 2080" => "2080-04-15",
      "१५ श्रावण २०८०" => "2080-04-15",
      "15 साउन, 2080 गते" => "2080-04-15",
      "2080/04/15 B.S." => "2080-04-15",
      "Baisakh 1, 2081" => "2081-01-01",
      "1 Baishakh 2081" => "2081-01-01",
      "30 Chaitra 2080" => "2080-12-30"
    }.each do |text, expected|
      assert_equal expected, NepDate::Date.parse_lenient(text).iso8601, text
    end
  end

  def test_lenient_rejections
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("10/05/20") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("80/05/15") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("15 Shrawan") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("Shrawan 15 2080 01") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("Shrawan Jestha 15 2080") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("not a date") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("12345/01/01") }
  end

  def test_the_closed_month_list_and_the_exact_case_fold
    assert_equal "2080-07-15", NepDate::Date.parse_lenient("KARTIK 15 2080").iso8601
    assert_equal "2080-07-15", NepDate::Date.parse_lenient("Kartik 15 2080").iso8601
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("Kartik 15 2080 ſ") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("सा\u200cउन 15 2080") }
  end

  def test_month_names_are_whole_tokens
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("Shr.15 2080") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("2080.B.S.") }
    assert_equal "2080-05-15", NepDate::Date.parse_lenient("2080.05.15").iso8601
  end

  def test_mixed_digits_and_unicode_oddities
    assert_equal "2080-05-15", NepDate::Date.parse("२०८०-05-१५").iso8601
    assert_raises(NepDate::ParseError) { NepDate::Date.parse("٢٠٨٠/05/15") }
    assert_raises(NepDate::ParseError) { NepDate::Date.parse_lenient("٢٠٨٠/05/15") }
  end
end
