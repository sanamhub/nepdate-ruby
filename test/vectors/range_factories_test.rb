# frozen_string_literal: true

require_relative "../test_helper"

# csharp-golden/range-factories.tsv (NR07-NR11): the named factories and the refused bounds.
class RangeFactoriesTest < Minitest::Test
  def test_each_row
    rows = Vectors.load("csharp-golden/range-factories.tsv")
    assert_equal 27, rows.length

    rows.each do |row|
      argument = row["argument"]
      parts = argument.split(",", -1)
      label = "#{row["factory"]} #{argument}"

      actual = case row["factory"]
      when "single_day"
        Outcome.range { NepDate::DateRange.single_day(Outcome.bs(argument)) }
      when "from_day_count"
        Outcome.range { NepDate::DateRange.from_day_count(Outcome.bs(parts[0]), parts[1].to_i) }
      when "for_month"
        Outcome.range { NepDate::DateRange.for_month(parts[0].to_i, parts[1].to_i) }
      when "for_calendar_year"
        Outcome.range { NepDate::DateRange.for_year(argument.to_i) }
      when "for_fiscal_year"
        Outcome.range { NepDate::FiscalYear.new(argument.to_i).range }
      when "construct"
        Outcome.range { NepDate::DateRange.new(Outcome.bs(parts[0]), Outcome.bs(parts[1])) }
      else
        flunk("unknown factory #{row["factory"]}")
      end

      Outcome.assert_matches(row["result"], actual, label)
    end
  end

  def test_every_factory_appears
    factories = Vectors.load("csharp-golden/range-factories.tsv").map { |row| row["factory"] }.uniq
    assert_equal 6, factories.length
  end

  def test_the_current_factories_use_an_explicit_clock_and_zone
    clock = -> { Time.utc(2024, 7, 30, 12, 0, 0) }
    today = NepDate::Date.today(zone: "+05:45", clock: clock)
    assert_equal "2081-04-15", today.iso8601
    assert NepDate::DateRange.current_month(zone: "+05:45", clock: clock).include?(today)
    assert NepDate::DateRange.current_calendar_year(zone: "+05:45", clock: clock).include?(today)
    assert NepDate::DateRange.current_fiscal_year(zone: "+05:45", clock: clock).include?(today)
    assert_equal "2081-04-01", NepDate::DateRange.current_fiscal_year(zone: "+05:45", clock: clock).start.iso8601
  end
end
