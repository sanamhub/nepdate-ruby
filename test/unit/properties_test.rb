# frozen_string_literal: true

require_relative "../test_helper"

# Seeded property loops, since Ruby has no standard property-testing library with the
# cross-language history of jqwik. A fixed seed makes every failure reproducible.
class PropertiesTest < Minitest::Test
  SEED = 20_811_015
  SAMPLES = 2_000

  def test_random_dates_round_trip_and_obey_their_invariants
    random = Random.new(SEED)
    SAMPLES.times do
      serial = random.rand(0..NepDate::CalendarTable::MAX_SERIAL)
      date = NepDate::Date.from_serial(serial)
      assert_equal serial, date.serial
      assert_equal date, NepDate::Date.from_date(date.to_date)
      assert_equal date, NepDate::Date.parse(date.iso8601)
      assert_equal date, NepDate::Date.from_ymd(date.to_ymd)
      assert_includes 1..12, date.month
      assert_includes 1..date.month_length, date.day
      assert_includes 29..32, date.month_length
      assert_includes 364..367, date.year_length
      assert_includes 0..6, date.weekday.number
      assert_equal date, date + 0
      assert_equal date, date.add_days(0)
    end
  end

  def test_random_day_offsets_invert
    random = Random.new(SEED + 1)
    SAMPLES.times do
      serial = random.rand(0..NepDate::CalendarTable::MAX_SERIAL)
      date = NepDate::Date.from_serial(serial)
      offset = random.rand(-1000..1000)
      next unless (0..NepDate::CalendarTable::MAX_SERIAL).cover?(serial + offset)

      moved = date.add_days(offset)
      assert_equal date, moved.add_days(-offset)
      assert_equal offset, date.days_until(moved)
      assert_equal(-offset, moved.days_until(date))
      assert_equal(-offset, date - moved)
    end
  end

  def test_random_month_offsets_stay_inside_the_year
    random = Random.new(SEED + 2)
    SAMPLES.times do
      date = NepDate::Date.from_serial(random.rand(0..NepDate::CalendarTable::MAX_SERIAL))
      months = random.rand(-240..240)
      begin
        moved = date.add_months(months)
      rescue NepDate::OutOfRangeError
        next
      end
      assert_includes 1..12, moved.month
      assert_includes 1..moved.month_length, moved.day
    end
  end

  def test_random_ranges_cover_their_days
    random = Random.new(SEED + 3)
    200.times do
      start = NepDate::Date.from_serial(random.rand(0..100_000))
      length = random.rand(1..100)
      last = start.add_days(length - 1)
      range = NepDate::DateRange.new(start, last)
      assert_equal length, range.length
      assert_equal last, range.to_a.last
      assert_equal range, range.union(range)
      assert_equal range, range.intersect(range)
      assert_empty range.except(range)
      assert_equal range.length, range.split_by_month.sum(&:length)
    end
  end

  def test_the_step_never_passes_the_end
    1_000.times do |index|
      start = NepDate::Date.from_serial((index * 109) % 109_212)
      step = index * 37 + 1
      range = NepDate::DateRange.new(start, start)
      dates = range.dates_with_interval(step)
      assert_equal [start], dates
    end
  end
end
