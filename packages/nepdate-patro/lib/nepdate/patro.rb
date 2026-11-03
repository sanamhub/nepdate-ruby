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
    # A binary search over an ascending frozen array of serials.
    # @api private
    module Lookup
      module_function

      def index_of(sorted, value)
        low = 0
        high = sorted.length - 1
        while low <= high
          middle = (low + high) / 2
          candidate = sorted[middle]
          return middle if candidate == value

          if candidate < value
            low = middle + 1
          else
            high = middle - 1
          end
        end
        nil
      end

      def include?(sorted, value)
        !index_of(sorted, value).nil?
      end
    end

    class << self
      # Everything the patro knows about +date+, never nil for the date itself. A day without
      # data returns a nil tithi, a false holiday flag and no events.
      def info(date)
        raise TypeError, "expected a NepDate::Date, got #{date.class}" unless date.is_a?(NepDate::Date)

        serial = date.serial
        tithi = if serial.between?(Table::TITHI_FIRST_SERIAL, Table::TITHI_LAST_SERIAL)
          index = Table::TITHI_INDEX.fetch(serial - Table::TITHI_FIRST_SERIAL)
          Tithi.new(*Table::NAMES.fetch(index))
        end

        events = []
        day_index = Lookup.index_of(Table::EVENT_DAY_SERIALS, serial)
        if day_index
          first = Table::EVENT_START.fetch(day_index)
          last = Table::EVENT_START.fetch(day_index + 1)
          (first...last).each do |position|
            events << Event.new(*Table::NAMES.fetch(Table::EVENTS_FLAT.fetch(position)))
          end
        end

        CalendarInfo.new(
          tithi: tithi,
          public_holiday: Lookup.include?(Table::HOLIDAY_SERIALS, serial),
          events: events
        )
      end
      alias_method :of, :info

      # The smallest BS range containing every day with tithi, holiday or event data.
      def coverage
        NepDate::DateRange.new(
          NepDate::Date.from_serial(Table::FIRST_SERIAL),
          NepDate::Date.from_serial(Table::LAST_SERIAL)
        )
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
