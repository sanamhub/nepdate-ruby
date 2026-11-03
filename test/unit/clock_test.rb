# frozen_string_literal: true

require_relative "../test_helper"

class ClockTest < Minitest::Test
  def test_the_clock_and_zone_are_explicit
    clock = -> { Time.utc(2024, 7, 30, 12, 0, 0) }
    assert_equal "2081-04-15", NepDate::Date.today(zone: "+05:45", clock: clock).iso8601
    assert_equal "2081-04-15", NepDate::Date.today(zone: "Asia/Kathmandu", clock: clock).iso8601
    assert_equal "2081-04-15", NepDate::Date.today(zone: 20_700, clock: clock).iso8601
    assert_equal "2081-04-15", NepDate::Date.today(zone: "UTC", clock: clock).iso8601
    assert_equal "2081-04-16", NepDate::Date.today(zone: "+05:45", clock: -> { Time.utc(2024, 7, 30, 18, 30) }).iso8601
    assert_equal "2081-04-15", NepDate::Date.today(zone: "UTC", clock: -> { Time.utc(2024, 7, 30, 18, 30) }).iso8601
  end

  def test_today_yesterday_and_tomorrow
    clock = -> { Time.utc(2024, 7, 30, 12, 0, 0) }
    today = NepDate::Date.today(zone: "UTC", clock: clock)
    assert today.today?(zone: "UTC", clock: clock)
    refute today.yesterday?(zone: "UTC", clock: clock)
    assert today.add_days(-1).yesterday?(zone: "UTC", clock: clock)
    assert today.add_days(1).tomorrow?(zone: "UTC", clock: clock)
    assert today.is_today(zone: "UTC", clock: clock)
    assert today.add_days(-1).is_yesterday(zone: "UTC", clock: clock)
    assert today.add_days(1).is_tomorrow(zone: "UTC", clock: clock)
    assert_equal "2081-04-15", today.iso8601
  end

  def test_zone_forms_and_errors
    assert_equal 20_700, NepDate::Date.offset_seconds("+05:45")
    assert_equal(-18_000, NepDate::Date.offset_seconds("-05:00"))
    assert_equal 0, NepDate::Date.offset_seconds("UTC")
    assert_equal 3_600, NepDate::Date.offset_seconds(3_600)
    assert_equal 7_200, NepDate::Date.offset_seconds(Struct.new(:utc_offset).new(7_200))
    assert_raises(ArgumentError) { NepDate::Date.offset_seconds("Asia/Tokyo") }
    assert_raises(ArgumentError) { NepDate::Date.offset_seconds(90_000) }
    assert_raises(TypeError) { NepDate::Date.today(clock: -> { "not a time" }) }
  end

  def test_a_datetime_clock_uses_its_date_part
    clock = -> { DateTime.new(2024, 7, 30, 23, 0, 0, Rational(20_700, 86_400)) }
    assert_equal "2081-04-15", NepDate::Date.today(zone: "+05:45", clock: clock).iso8601
    clock = -> { ::Date.new(2024, 7, 30) }
    assert_equal "2081-04-15", NepDate::Date.today(clock: clock).iso8601
  end
end
