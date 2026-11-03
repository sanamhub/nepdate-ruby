# frozen_string_literal: true

require_relative "../test_helper"
require "json"

# csharp-golden/serialization.tsv (NC10, D-11): the native JSON hook, a quoted YYYY-MM-DD.
class SerializationTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/serialization.tsv")
    assert_equal 11, rows.length

    rows.each do |row|
      case row["kind"]
      when "write"
        assert_equal row["json"], JSON.generate(NepDate::Date.parse(row["input"])), row["input"]
      when "read"
        Outcome.assert_matches(
          row["result"],
          Outcome.date { NepDate::Date.from_json(row["input"]) },
          row["input"]
        )
      when "roundtrip"
        written = JSON.generate(NepDate::Date.parse(row["input"]))
        assert_equal row["json"], written, row["input"]
        Outcome.assert_matches(
          row["result"],
          Outcome.date { NepDate::Date.from_json(written) },
          row["input"]
        )
      else
        flunk("unknown kind #{row["kind"]}")
      end
    end
  end

  def test_the_written_form_is_a_quoted_string
    date = NepDate::Date.parse("2081-04-15")
    assert_equal '"2081-04-15"', date.to_json
    assert_equal '{"d":"2081-04-15"}', JSON.generate({d: date})
    assert_equal({"year" => 2081, "month" => 4, "day" => 15}, JSON.parse(date.to_h.to_json))
    assert_raises(NepDate::ParseError) { NepDate::Date.from_json("null") }
    assert_raises(NepDate::ParseError) { NepDate::Date.from_json("{\"year\":2081}") }
    assert_raises(NepDate::ParseError) { NepDate::Date.from_json("not json") }
  end
end
