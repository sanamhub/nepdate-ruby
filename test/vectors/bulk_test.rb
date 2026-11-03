# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/bulk.tsv (NC04-NC08): ordered batch conversion, one function each way.
class BulkTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/bulk.tsv")
    assert_equal 6, rows.length

    rows.each do |row|
      input = row["input"].split(";")
      actual = case row["operation"]
      when "to_nepali_dates", "batch_to_nepali_dates"
        Outcome.date_list { NepDate::Date.from_gregorian_batch(gregorian(input)) }
      when "to_english_dates_from_strings"
        english { NepDate::Date.parse_batch(input) }
      when "to_english_dates_from_dates"
        english { NepDate::Date.to_gregorian_batch(nepali(input)) }
      when "batch_to_english_dates"
        english { NepDate::Date.to_gregorian_batch(nepali(input)) }
      else
        flunk("unknown operation #{row["operation"]}")
      end

      Outcome.assert_matches(row["output"], actual, row["operation"])
    end
  end

  def test_the_result_keeps_input_order
    dates = gregorian(["2024-07-31", "1844-04-11", "2143-04-15"])
    converted = NepDate::Date.from_gregorian_batch(dates)
    assert_equal ["2081-04-16", "1901-01-01", "2199-12-30"], converted.map(&:iso8601)
    assert_equal ["2024-07-31", "1844-04-11", "2143-04-15"],
      NepDate::Date.to_gregorian_batch(converted).map(&:iso8601)
    assert_equal ["2024-07-31", "1844-04-11", "2143-04-15"],
      NepDate::Date.parse_batch(["2081-04-16", "1901-01-01", "2199-12-30"]).map(&:iso8601)
  end

  private

  def gregorian(texts)
    texts.map { |text| ::Date.iso8601(text) }
  end

  def nepali(texts)
    texts.map { |text| NepDate::Date.parse(text) }
  end

  def english
    dates = yield
    parts = dates.map(&:iso8601)
    parts.join(";")
  rescue NepDate::Error => e
    "ERR:#{e.kind_name}"
  end
end
