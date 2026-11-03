# frozen_string_literal: true

module NepDate
  module Patro
    # Everything the patro knows about one BS date. A date without data has a +nil+ tithi, a
    # false holiday flag and an empty event list; +info+ never fails.
    class CalendarInfo
      attr_reader :tithi, :events

      def initialize(tithi: nil, public_holiday: false, events: [])
        @tithi = tithi
        @public_holiday = public_holiday ? true : false
        @events = events.freeze
        freeze
      end

      def public_holiday?
        @public_holiday
      end
      alias_method :is_public_holiday, :public_holiday?
      alias_method :holiday?, :public_holiday?

      def tithi_np
        tithi&.nepali || ""
      end

      def tithi_en
        tithi&.english || ""
      end

      def events_np
        events.map(&:nepali)
      end

      def events_en
        events.map(&:english)
      end

      def to_h
        {
          tithi: tithi&.to_h,
          public_holiday: public_holiday?,
          events: events.map(&:to_h)
        }
      end

      def ==(other)
        other.is_a?(CalendarInfo) &&
          tithi == other.tithi &&
          public_holiday? == other.public_holiday? &&
          events == other.events
      end
      alias_method :eql?, :==

      def hash
        [CalendarInfo, tithi, public_holiday?, events].hash
      end

      def inspect
        "#<NepDate::Patro::CalendarInfo tithi=#{tithi&.english.inspect} holiday=#{public_holiday?} " \
          "events=#{events_en.inspect}>"
      end
    end
  end
end
