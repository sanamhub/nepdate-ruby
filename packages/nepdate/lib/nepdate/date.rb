# frozen_string_literal: true

require "date"
require "json"

module NepDate
  # A date in the Bikram Sambat calendar, from 1901-01-01 to 2199-12-30 BS (AD 1844-04-11 to
  # 2143-04-15). Immutable, always a real day, and ordered by its serial day.
  #
  # The class is named +NepDate::Date+ to read naturally as +NepDate::Date.parse("2081-04-15")+.
  # The Gregorian type is the standard library's +::Date+; the two never share a namespace.
  class Date
    include Comparable

    # Nepal's fixed UTC offset, 5 hours 45 minutes, used when no zone is given. Nepal has no
    # daylight saving time, so a fixed offset is the complete rule.
    DEFAULT_OFFSET = 20_700
    DEFAULT_ZONE = "Asia/Kathmandu"
    OFFSET_ALIASES = {
      "Asia/Kathmandu" => 20_700,
      "Asia/Katmandu" => 20_700,
      "NPT" => 20_700,
      "UTC" => 0,
      "GMT" => 0,
      "Z" => 0
    }.freeze

    attr_reader :year, :month, :day, :serial

    def initialize(year, month, day)
      year = Date.integer_argument(year, "year")
      month = Date.integer_argument(month, "month")
      day = Date.integer_argument(day, "day")
      index = year - CalendarTable::MIN_YEAR
      unless index >= 0 && index < CalendarTable::YEARS
        raise OutOfRangeError, "year #{year} is outside #{CalendarTable::MIN_YEAR}..#{CalendarTable::MAX_YEAR}"
      end
      unless month.between?(1, 12)
        raise InvalidMonthError, "month #{month} is outside 1..12"
      end

      packed = CalendarTable::PACKED.fetch(index)
      length = 29 + ((packed >> (2 * (month - 1))) & 0b11)
      unless day.between?(1, length)
        raise InvalidDayError, "day #{day} is outside 1..#{length}"
      end

      initialize_parts(year, month, day, CalendarTable::MONTH_START.fetch(index * 12 + month - 1) + day - 1)
    end

    class << self
      # Builds a BS date and validates the year, then the month, then the day.
      def from_bs(year, month, day)
        new(year, month, day)
      end
      alias_method :from_ymd_parts, :from_bs

      # Converts a real AD day. The date part is what converts; a time of day is discarded.
      def from_gregorian(year, month, day)
        year = integer_argument(year, "year")
        month = integer_argument(month, "month")
        day = integer_argument(day, "day")

        unless Calendar.valid_gregorian?(year, month, day)
          raise InvalidGregorianError, "#{year}-#{month}-#{day} is not a real Gregorian date"
        end

        serial = Calendar.days_from_civil(year, month, day) - CalendarTable::EPOCH_UNIX_DAYS
        unless serial.between?(0, CalendarTable::MAX_SERIAL)
          raise OutOfRangeError, "#{year}-#{month}-#{day} is outside the supported range"
        end

        from_serial(serial)
      end

      # Converts a standard library +::Date+ or +::DateTime+ by its date part.
      def from_date(value)
        unless value.is_a?(::Date)
          raise ArgumentError, "expected a ::Date, got #{value.class}"
        end

        # ::Date already validates its fields, so its Julian day is the serial plus a constant.
        from_serial(value.jd - CalendarTable::JULIAN_EPOCH)
      end

      # Converts a +Time+ in the time's own offset.
      def from_time(value)
        unless value.is_a?(::Time)
          raise ArgumentError, "expected a ::Time, got #{value.class}"
        end

        from_gregorian(value.year, value.month, value.day)
      end

      # The first supported date: 1901-01-01 BS.
      def min
        MIN
      end

      # The last supported date: 2199-12-30 BS.
      def max
        MAX
      end

      # Today in +zone+. The zone may be an IANA name for Nepal, +"UTC"+, a fixed offset such as
      # +"+05:45"+, an integer number of seconds, or an object that responds to +utc_offset+.
      # Pass +clock:+ to replace +Time.now+; the callable returns a +Time+, +DateTime+ or +Date+.
      def today(zone: DEFAULT_ZONE, clock: nil)
        offset = offset_seconds(zone)
        now = clock ? clock.call : Time.now
        case now
        when ::Time
          local = now.getlocal(offset)
          from_gregorian(local.year, local.month, local.day)
        when ::DateTime
          from_gregorian(now.year, now.month, now.day)
        when ::Date
          from_gregorian(now.year, now.month, now.day)
        else
          raise TypeError, "clock must return a Time, DateTime or Date, got #{now.class}"
        end
      end

      # The strict parser of PARSING.md section 1: year, month, day, ASCII or Devanagari digits.
      def parse(text)
        year, month, day = Parse.strict(text)
        new(year, month, day)
      end

      # The strict parser without an exception. Returns +nil+ on any NepDate error.
      def try_parse(text)
        parse(text)
      rescue Error
        nil
      end

      # The deterministic human-input parser of PARSING.md section 2.
      def parse_lenient(text)
        year, month, day = Lenient.parse(text)
        new(year, month, day)
      end

      # The lenient parser without an exception. Returns +nil+ on any NepDate error.
      def try_parse_lenient(text)
        parse_lenient(text)
      rescue Error
        nil
      end

      # Reads the +YYYYMMDD+ integer. Values outside the eight-digit form are rejected rather
      # than split or truncated.
      def from_ymd(value)
        value = integer_argument(value, "ymd")
        unless (0..99_999_999).cover?(value)
          raise OutOfRangeError, "#{value} is not a positive eight-digit YYYYMMDD value"
        end

        new(value / 10_000, (value / 100) % 100, value % 100)
      end
      alias_method :from_ymd_int, :from_ymd

      # Reads the JSON string written by +to_json+: a quoted "YYYY-MM-DD" value. A JSON null or
      # object is rejected, because this port has no zero date (D-01, D-11).
      def from_json(text)
        value = JSON.parse(text)
        unless value.is_a?(String)
          raise ParseError.new(ErrorKind::INVALID_CHARACTER, "the JSON value is not a string")
        end

        parse(value)
      rescue JSON::ParserError
        raise ParseError.new(ErrorKind::INVALID_CHARACTER, "the text is not a JSON string")
      end

      # Ordered batch conversion from AD dates. Accepts +::Date+, +DateTime+ and +Time+ values
      # and keeps input order (D-11).
      def from_gregorian_batch(dates)
        dates.map do |value|
          case value
          when Date then value
          when ::Time then from_time(value)
          when ::Date then from_date(value)
          else
            raise ArgumentError, "expected a Date, DateTime or Time, got #{value.class}"
          end
        end
      end

      # Ordered batch conversion from BS text to AD +::Date+ values (D-11).
      def parse_batch(texts)
        texts.map { |text| parse(text).to_date }
      end

      # Ordered batch conversion from BS dates to AD +::Date+ values (D-11).
      def to_gregorian_batch(dates)
        dates.map(&:to_date)
      end

      # The first boundary of the proleptic Gregorian calendar supported by this port.
      def min_gregorian
        MIN.to_date
      end

      # The last boundary of the proleptic Gregorian calendar supported by this port.
      def max_gregorian
        MAX.to_date
      end

      # Matches a fixed offset from a string, an integer or an object with +utc_offset+.
      # @api private
      def offset_seconds(zone)
        offset =
          case zone
          when Integer then zone
          when String
            OFFSET_ALIASES.fetch(zone) do
              match = /\A([+-])(\d{2}):?(\d{2})\z/.match(zone)
              raise ArgumentError, "invalid UTC offset #{zone.inspect}" unless match

              seconds = match[2].to_i * 3600 + match[3].to_i * 60
              (match[1] == "-") ? -seconds : seconds
            end
          when nil then DEFAULT_OFFSET
          else
            if zone.respond_to?(:utc_offset)
              zone.utc_offset
            else
              raise ArgumentError, "zone must be an offset string, integer or utc_offset object, got #{zone.inspect}"
            end
          end

        unless (-86_400...86_400).cover?(offset)
          raise ArgumentError, "UTC offset #{offset} seconds is outside one day"
        end

        offset
      end

      # Builds a date whose parts and serial are already known to be valid. Used by the
      # conversion and arithmetic paths, so they do not validate and recompute a serial twice.
      # @api private
      def from_parts(year, month, day, serial)
        date = allocate
        date.send(:initialize_parts, year, month, day, serial)
        date
      end

      # @api private
      def from_serial(serial)
        unless serial.between?(0, CalendarTable::MAX_SERIAL)
          raise OutOfRangeError, "serial #{serial} is outside 0..#{CalendarTable::MAX_SERIAL}"
        end

        index = CalendarTable::BUCKET[serial >> 5]
        index += 1 if serial >= CalendarTable::MONTH_START[index + 1]
        index += 1 if serial >= CalendarTable::MONTH_START[index + 1]
        from_parts(
          CalendarTable::MIN_YEAR + index / 12,
          index % 12 + 1,
          serial - CalendarTable::MONTH_START[index] + 1,
          serial
        )
      end

      # Public integer arguments are never coerced from floats or strings, so a truncated value
      # cannot silently become a different date.
      # @api private
      def integer_argument(value, label)
        return value if value.is_a?(Integer)

        raise TypeError, "#{label} must be an Integer, got #{value.class}"
      end
    end

    # The BS ordinal in this BS year, starting at 1 on Baishakh 1.
    def day_of_year
      serial - CalendarTable::YEAR_START.fetch(year - CalendarTable::MIN_YEAR) + 1
    end

    # The BS year length, 364 to 367 days (D-12), not Gregorian leap-ness.
    def year_length
      index = year - CalendarTable::MIN_YEAR
      CalendarTable::YEAR_START.fetch(index + 1) - CalendarTable::YEAR_START.fetch(index)
    end

    # The last valid day of this BS month, 29 to 32.
    def month_length
      Calendar.month_length(year, month)
    end
    alias_method :month_end_day, :month_length

    def month_enum
      Month.from(month)
    end
    alias_method :month_name, :month_enum

    def weekday
      Weekday.from((serial + CalendarTable::EPOCH_WEEKDAY) % 7)
    end
    alias_method :day_of_week, :weekday

    # This year and month on the last day.
    def last_day_of_month
      length = month_length
      Date.from_parts(year, month, length, serial - day + length)
    end
    alias_method :month_end_date, :last_day_of_month

    def to_date
      civil = Calendar.civil_from_days(serial + CalendarTable::EPOCH_UNIX_DAYS)
      ::Date.new(*civil)
    end
    alias_method :english_date, :to_date

    def to_datetime(zone: DEFAULT_ZONE)
      offset = Date.offset_seconds(zone)
      ::DateTime.new(year, month, day, 0, 0, 0, Rational(offset, 86_400))
    end

    def to_time(zone: DEFAULT_ZONE, hour: 0, minute: 0, second: 0)
      offset = Date.offset_seconds(zone)
      civil = Calendar.civil_from_days(serial + CalendarTable::EPOCH_UNIX_DAYS)
      ::Time.new(civil[0], civil[1], civil[2], hour, minute, second, offset)
    end

    def today?(zone: DEFAULT_ZONE, clock: nil)
      self == Date.today(zone: zone, clock: clock)
    end
    alias_method :is_today, :today?

    def yesterday?(zone: DEFAULT_ZONE, clock: nil)
      self == Date.today(zone: zone, clock: clock).add_days(-1)
    end
    alias_method :is_yesterday, :yesterday?

    def tomorrow?(zone: DEFAULT_ZONE, clock: nil)
      self == Date.today(zone: zone, clock: clock).add_days(1)
    end
    alias_method :is_tomorrow, :tomorrow?

    def fiscal_year
      FiscalYear.containing(self)
    end

    def quarter
      case month
      when 4..6 then Quarter::Q1
      when 7..9 then Quarter::Q2
      when 10..12 then Quarter::Q3
      else Quarter::Q4
      end
    end

    def add_days(days)
      unless days.is_a?(Integer)
        raise TypeError, "days must be an Integer, got #{days.class}"
      end

      target = serial + days
      unless target.between?(0, CalendarTable::MAX_SERIAL)
        raise OutOfRangeError, "day offset #{days} is outside the supported range"
      end

      Date.from_serial(target)
    end

    def add_months(months, overflow: :clamp)
      unless months.is_a?(Integer)
        raise TypeError, "months must be an Integer, got #{months.class}"
      end

      mode = (overflow == :clamp || overflow == :spill) ? overflow : MonthOverflow.coerce(overflow)
      total = (year - CalendarTable::MIN_YEAR) * 12 + (month - 1) + months
      if total < 0 || total >= CalendarTable::YEARS * 12
        raise OutOfRangeError, "month offset #{months} is outside the supported range"
      end

      target_year = CalendarTable::MIN_YEAR + total / 12
      target_month = total % 12 + 1
      target_index = total
      packed = CalendarTable::PACKED.fetch(target_year - CalendarTable::MIN_YEAR)
      length = 29 + ((packed >> (2 * (target_month - 1))) & 0b11)
      target_start = CalendarTable::MONTH_START.fetch(target_index)

      if day <= length
        return Date.from_parts(target_year, target_month, day, target_start + day - 1)
      end
      if mode == :clamp
        return Date.from_parts(target_year, target_month, length, target_start + length - 1)
      end

      spill_year = (target_month == 12) ? target_year + 1 : target_year
      spill_month = (target_month == 12) ? 1 : target_month + 1
      if spill_year > CalendarTable::MAX_YEAR
        raise OutOfRangeError, "month offset #{months} spills past the supported range"
      end

      spill_day = day - length
      Date.from_parts(
        spill_year, spill_month, spill_day,
        CalendarTable::MONTH_START.fetch(target_index + 1) + spill_day - 1
      )
    end

    def add_years(years, overflow: :clamp)
      years = Date.integer_argument(years, "years")
      add_months(years * 12, overflow: overflow)
    end

    # +other - self+, the direction of ALGORITHM.md +days_between(a, b)+ (D-07).
    def days_until(other)
      expect_date!(other)
      other.serial - serial
    end

    # The signed years, months and days from +self+ to +other+ (ALGORITHM.md section 8a).
    def diff(other)
      expect_date!(other)
      if self <= other
        low = self
        high = other
        negative = false
      else
        low = other
        high = self
        negative = true
      end

      months = (high.year - low.year) * 12 + (high.month - low.month)
      anchor = low.add_months(months)
      if anchor > high
        months -= 1
        anchor = low.add_months(months)
      end

      DateDiff.new(
        negative: negative,
        years: months / 12,
        months: months % 12,
        days: high.serial - anchor.serial,
        total_days: days_until(other)
      )
    end
    alias_method :calendar_breakdown, :diff

    def succ
      add_days(1)
    end

    def +(other)
      return add_days(other) if other.is_a?(Integer)

      raise TypeError, "can only add an Integer to a NepDate::Date"
    end

    # +self - other+ keeps the C# direction and is positive when self is later (D-07). Subtracting
    # an integer is the Ruby convenience for moving backwards.
    def -(other)
      return add_days(-other) if other.is_a?(Integer)

      expect_date!(other)
      serial - other.serial
    end

    def <=>(other)
      return nil unless other.is_a?(Date)

      serial <=> other.serial
    end

    def compare_to(other)
      self <=> other
    end

    def ==(other)
      other.is_a?(Date) && serial == other.serial
    end
    alias_method :eql?, :==

    def hash
      [Date, serial].hash
    end

    def to_ymd
      year * 10_000 + month * 100 + day
    end
    alias_method :ymd, :to_ymd

    def iso8601
      Format.iso8601(year, month, day, :en)
    end
    alias_method :isoformat, :iso8601

    def to_s
      Format.default(year, month, day, :en)
    end

    def to_short_string(order: :ymd, separator: :slash, pad: true, lang: :en)
      Format.short(year, month, day, order: order, separator: separator, pad: pad, lang: lang)
    end

    def to_long_string(weekday: false, year: true, pad: true, lang: :en)
      lang = Lang.coerce(lang) unless lang == :en || lang == :ne
      if lang == :ne
        day_text = pad ? Names::TWO_DIGIT_NE[@day] : Names::NUMBER_NE[@day]
        year_text = Names::YEAR_NE[@year - CalendarTable::MIN_YEAR]
        month_text = Names::MONTH_NE[@month]
        weekday_text = Names::WEEKDAY_NE[(serial + CalendarTable::EPOCH_WEEKDAY) % 7] if weekday
      else
        day_text = pad ? Names::TWO_DIGIT_EN[@day] : Names::NUMBER_EN[@day]
        year_text = Names::YEAR_EN[@year - CalendarTable::MIN_YEAR]
        month_text = Names::MONTH_EN[@month]
        weekday_text = Names::WEEKDAY_EN[(serial + CalendarTable::EPOCH_WEEKDAY) % 7] if weekday
      end

      text = +""
      text << weekday_text << ", " if weekday
      text << month_text << " " << day_text
      text << ", " << year_text if year
      text
    end

    def to_unicode_string(order: :ymd, separator: :slash, pad: true)
      to_short_string(order: order, separator: separator, pad: pad, lang: :ne)
    end

    def to_long_unicode_string(weekday: false, year: true, pad: true)
      to_long_string(weekday: weekday, year: year, pad: pad, lang: :ne)
    end

    def format(pattern, lang: :en)
      Format.pattern(pattern, year: year, month: month, day: day, lang: lang)
    end

    # The canonical string form, +YYYY-MM-DD+, read by +from_json+.
    def to_json(*_args)
      JSON.generate(iso8601)
    end

    def to_h
      {year: year, month: month, day: day}
    end

    def to_a
      [year, month, day]
    end
    alias_method :to_ary, :to_a

    def deconstruct
      to_a
    end

    def deconstruct_keys(_keys)
      to_h
    end

    def inspect
      "#<NepDate::Date #{iso8601}>"
    end

    private

    def initialize_parts(year, month, day, serial)
      @year = year
      @month = month
      @day = day
      @serial = serial
      freeze
    end

    def expect_date!(other)
      raise TypeError, "expected a NepDate::Date, got #{other.class}" unless other.is_a?(Date)

      other
    end

    MIN = from_bs(CalendarTable::MIN_YEAR, 1, 1)
    MAX = from_bs(CalendarTable::MAX_YEAR, 12, Calendar.month_length(CalendarTable::MAX_YEAR, 12))
  end
end
