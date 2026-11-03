# frozen_string_literal: true

require_relative "../test_helper"

# Every serial in the supported range converts both ways. This is the strongest check of the
# generated table and the binary search, and it is fast enough to stay in the normal suite.
class ExhaustiveTest < Minitest::Test
  def test_every_serial_round_trips
    (0..NepDate::CalendarTable::MAX_SERIAL).each do |serial|
      date = NepDate::Date.from_serial(serial)
      assert_equal serial, date.serial, "serial #{serial}"
      assert_equal date, NepDate::Date.from_date(date.to_date), "serial #{serial}"
    end
  end

  def test_serial_boundaries
    assert_equal 0, NepDate::Date::MIN.serial
    assert_equal 109_211, NepDate::Date::MAX.serial
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date.from_serial(-1) }
    assert_raises(NepDate::OutOfRangeError) { NepDate::Date.from_serial(109_212) }
  end
end
