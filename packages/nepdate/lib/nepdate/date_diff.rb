# frozen_string_literal: true

module NepDate
  # The signed calendar breakdown between two dates (ALGORITHM.md section 8a). +negative+ is
  # true when the second date is earlier; +total_days+ is the signed day count in the direction
  # from the first date to the second.
  class DateDiff
    attr_reader :years, :months, :days, :total_days

    def initialize(negative:, years:, months:, days:, total_days:)
      @negative = negative
      @years = years
      @months = months
      @days = days
      @total_days = total_days
      freeze
    end

    def negative?
      @negative
    end

    def sign
      negative? ? -1 : 1
    end

    def to_h
      {negative: negative?, years: years, months: months, days: days, total_days: total_days}
    end

    def ==(other)
      other.is_a?(DateDiff) &&
        negative? == other.negative? &&
        years == other.years &&
        months == other.months &&
        days == other.days &&
        total_days == other.total_days
    end
    alias_method :eql?, :==

    def hash
      [DateDiff, negative?, years, months, days, total_days].hash
    end

    def inspect
      "#<NepDate::DateDiff #{negative? ? "-" : "+"}#{years}y #{months}m #{days}d total=#{total_days}>"
    end
  end
end
