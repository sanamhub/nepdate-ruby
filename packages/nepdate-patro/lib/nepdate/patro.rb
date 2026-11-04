# frozen_string_literal: true

require "nepdate"
require_relative "patro/version"
require_relative "patro/table"
require_relative "patro/named"
require_relative "patro/calendar_info"

module NepDate
  # The patro (पात्रो, the Nepali almanac): tithi, public holidays and events per BS day. It is
  # a separate gem that depends on +nepdate+; the core gem has no almanac data.
  module Patro
    # Builds one immutable CalendarInfo per coverage day, sharing the tithi and event objects. A
    # lookup is then an array read, as in the Python port, instead of a binary search and three
    # allocations per call.
    def self.build_day_info(serial, holiday, event_days)
      tithi = if serial.between?(Table::TITHI_FIRST_SERIAL, Table::TITHI_LAST_SERIAL)
        TITHI_OBJECTS[Table::TITHI_INDEX[serial - Table::TITHI_FIRST_SERIAL]]
      end
      public_holiday = holiday.key?(serial)
      events = EMPTY_EVENTS
      position = event_days[serial]
      if position
        first = Table::EVENT_START[position]
        last = Table::EVENT_START[position + 1]
        events = Array.new(last - first) { |offset| EVENT_OBJECTS[Table::EVENTS_FLAT[first + offset]] }
      end

      if tithi.nil? && !public_holiday && events.empty?
        EMPTY_INFO
      else
        CalendarInfo.new(tithi: tithi, public_holiday: public_holiday, events: events)
      end
    end
    private_class_method :build_day_info

    TITHI_OBJECTS = Table::NAMES.map { |nepali, english| Tithi.new(nepali, english) }.freeze
    EVENT_OBJECTS = Table::NAMES.map { |nepali, english| Event.new(nepali, english) }.freeze
    EMPTY_EVENTS = [].freeze
    EMPTY_INFO = CalendarInfo.new
    DAY_INFO = begin
      holiday = {}
      Table::HOLIDAY_SERIALS.each { |serial| holiday[serial] = true }
      event_days = {}
      Table::EVENT_DAY_SERIALS.each_with_index { |serial, index| event_days[serial] = index }
      info = Array.new(CalendarTable::TOTAL_DAYS, EMPTY_INFO)
      (Table::FIRST_SERIAL..Table::LAST_SERIAL).each do |serial|
        info[serial] = build_day_info(serial, holiday, event_days)
      end
      info.freeze
    end
    COVERAGE = NepDate::DateRange.new(
      NepDate::Date.from_serial(Table::FIRST_SERIAL),
      NepDate::Date.from_serial(Table::LAST_SERIAL)
    )

    class << self
      # Everything the patro knows about +date+, never nil for the date itself. A day without
      # data returns a nil tithi, a false holiday flag and no events.
      def info(date)
        raise TypeError, "expected a NepDate::Date, got #{date.class}" unless date.is_a?(NepDate::Date)

        DAY_INFO[date.serial]
      end
      alias_method :of, :info

      # The smallest BS range containing every day with tithi, holiday or event data.
      def coverage
        COVERAGE
      end

      # Every gazetted public holiday, ascending.
      def public_holidays
        Table::HOLIDAY_SERIALS.map { |serial| NepDate::Date.from_serial(serial) }
      end
    end
  end
end

module NepDate
  class Date
    # One lookup returning the tithi, holiday flag and events of this date. It comes from the
    # patro gem, so the core has no reference to it (D-13).
    def calendar_info
      Patro.info(self)
    end
  end
end
