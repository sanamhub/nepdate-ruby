# frozen_string_literal: true

module NepDate
  # An inclusive, non-empty span of consecutive BS dates. It includes Enumerable, so +each+,
  # +map+, +select+, +to_a+ and the rest work; +length+ is the inclusive day count.
  class DateRange
    include Enumerable

    attr_reader :start, :end

    def initialize(start, finish)
      raise TypeError, "start must be a NepDate::Date, got #{start.class}" unless start.is_a?(Date)
      raise TypeError, "end must be a NepDate::Date, got #{finish.class}" unless finish.is_a?(Date)
      raise OutOfRangeError, "a range must not start after it ends" if start > finish

      @start = start
      @end = finish
      freeze
    end

    class << self
      def of(start, finish)
        new(start, finish)
      end

      def single_day(date)
        new(date, date)
      end

      def from_day_count(start, days)
        days = Date.integer_argument(days, "days")
        raise OutOfRangeError, "a range must span at least one day" if days < 1

        new(start, start.add_days(days - 1))
      end

      def for_month(year, month)
        first = Date.from_bs(year, month, 1)
        new(first, first.last_day_of_month)
      end

      def for_year(year)
        first = Date.from_bs(year, 1, 1)
        new(first, Date.from_bs(year, 12, Calendar.month_length(year, 12)))
      end

      def current_month(zone: Date::DEFAULT_ZONE, clock: nil)
        today = Date.today(zone: zone, clock: clock)
        for_month(today.year, today.month)
      end

      def current_fiscal_year(zone: Date::DEFAULT_ZONE, clock: nil)
        FiscalYear.containing(Date.today(zone: zone, clock: clock)).range
      end

      def current_calendar_year(zone: Date::DEFAULT_ZONE, clock: nil)
        for_year(Date.today(zone: zone, clock: clock).year)
      end
    end

    def length
      self.end.serial - start.serial + 1
    end
    alias_method :size, :length

    def first(count = nil)
      return start if count.nil?

      to_a.first(count)
    end

    def last(count = nil)
      return self.end if count.nil?

      to_a.last(count)
    end

    def empty?
      false
    end

    def include?(date)
      raise TypeError, "expected a NepDate::Date, got #{date.class}" unless date.is_a?(Date)

      date.between?(start, self.end)
    end
    alias_method :contains?, :include?
    alias_method :contains, :include?

    def contains_range?(other)
      expect_range!(other)
      include?(other.start) && include?(other.end)
    end
    alias_method :contains_range, :contains_range?

    def overlaps?(other)
      expect_range!(other)
      start <= other.end && other.start <= self.end
    end
    alias_method :overlaps, :overlaps?

    # True when one range starts the day after the other ends. A range cannot start before
    # 1901-01-01 or after 2199-12-30, so a range that ends at the data edge simply has no
    # adjacent successor and is never advanced past it (D-16).
    def adjacent_to?(other)
      expect_range!(other)
      if self.end < other.start
        self.end.add_days(1) == other.start
      elsif other.end < start
        other.end.add_days(1) == start
      else
        false
      end
    end
    alias_method :is_adjacent_to, :adjacent_to?

    # The overlap, or +nil+ when the ranges do not touch (D-01, D-16).
    def intersect(other)
      expect_range!(other)
      first = (start >= other.start) ? start : other.start
      last = (self.end <= other.end) ? self.end : other.end
      return nil if first > last

      DateRange.new(first, last)
    end

    # The smallest range covering both, not a set union.
    def union(other)
      expect_range!(other)
      first = (start <= other.start) ? start : other.start
      last = (self.end >= other.end) ? self.end : other.end
      DateRange.new(first, last)
    end

    # This range with the other removed: zero, one or two ranges.
    def except(other)
      expect_range!(other)
      overlap = intersect(other)
      return [self] if overlap.nil?

      result = []
      result << DateRange.new(start, overlap.start.add_days(-1)) if start < overlap.start
      result << DateRange.new(overlap.end.add_days(1), self.end) if self.end > overlap.end
      result
    end

    def split_by_month
      result = []
      cursor = start
      while cursor <= self.end
        month_end = cursor.last_day_of_month
        segment_end = (month_end <= self.end) ? month_end : self.end
        result << DateRange.new(cursor, segment_end)
        break if segment_end == self.end

        cursor = segment_end.add_days(1)
      end
      result
    end

    def split_by_fiscal_quarter
      result = []
      cursor = start
      while cursor <= self.end
        quarter_end = cursor.fiscal_year.quarter_range(cursor.quarter).end
        segment_end = (quarter_end <= self.end) ? quarter_end : self.end
        result << DateRange.new(cursor, segment_end)
        break if segment_end == self.end

        cursor = segment_end.add_days(1)
      end
      result
    end

    def dates_with_interval(step = 1)
      step = Date.integer_argument(step, "step")
      raise OutOfRangeError, "the step must be at least 1" if step < 1

      result = []
      cursor = start
      loop do
        result << cursor
        remaining = cursor.days_until(self.end)
        break if remaining < step

        cursor = cursor.add_days(step)
      end
      result
    end

    # Every day except Saturday, and except Sunday when +exclude_sunday+ is true.
    def working_days(exclude_sunday: false)
      each.select do |date|
        !date.weekday.saturday? && !(exclude_sunday && date.weekday.sunday?)
      end
    end

    # Every Saturday, and Sunday when +include_sunday+ is true.
    def weekend_days(include_sunday: true)
      each.select do |date|
        date.weekday.saturday? || (include_sunday && date.weekday.sunday?)
      end
    end

    def each
      return enum_for(:each) unless block_given?

      serial = start.serial
      last = self.end.serial
      while serial <= last
        yield Date.from_serial(serial)
        serial += 1
      end
      self
    end

    def ==(other)
      other.is_a?(DateRange) && start == other.start && self.end == other.end
    end
    alias_method :eql?, :==

    def hash
      [DateRange, start, self.end].hash
    end

    def to_s
      "#{start} - #{self.end}"
    end

    def to_short_string(order: :ymd, separator: :slash, lang: :en)
      "#{start.to_short_string(order: order, separator: separator, lang: lang)} - " \
        "#{self.end.to_short_string(order: order, separator: separator, lang: lang)}"
    end

    def to_h
      {start: start, end: self.end}
    end

    def inspect
      "#<NepDate::DateRange #{start.iso8601}..#{self.end.iso8601}>"
    end

    private

    def expect_range!(other)
      raise TypeError, "expected a NepDate::DateRange, got #{other.class}" unless other.is_a?(DateRange)

      other
    end
  end
end
