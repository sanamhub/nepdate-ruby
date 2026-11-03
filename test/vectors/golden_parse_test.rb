# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/parse.tsv: the C# results, kept for comparison only. D-05 lets the strict
# parser accept Devanagari digits and cap the group length, so rows where C# failed and this
# port accepted a Devanagari digit are the only allowed disagreements. D-06 replaces the
# smart column completely; it is deliberately not asserted.
class GoldenParseTest < Minitest::Test
  def test_the_strict_column
    rows = Vectors.load("csharp-golden/parse.tsv")
    rows.each do |row|
      input = row["input"]
      actual = Outcome.date { NepDate::Date.parse(input) }
      if Vectors.error?(row["strict"]) && !Vectors.error?(actual) && input.match?(/[\u0966-\u096F]/)
        next
      end

      Outcome.assert_matches(row["strict"], actual, "strict #{input.inspect}")
    end
  end

  def test_the_smart_column_is_not_the_lenient_parser
    diverged = 0
    Vectors.load("csharp-golden/parse.tsv").each do |row|
      next if Vectors.error?(row["smart"])

      lenient = Outcome.date { NepDate::Date.parse_lenient(row["input"]) }
      diverged += 1 if lenient != row["smart"]
    end
    assert_operator diverged, :>, 0, "D-06 is expected to differ somewhere"
  end
end
