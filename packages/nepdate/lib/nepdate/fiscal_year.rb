# frozen_string_literal: true

module NepDate
  # A fiscal year, 1 Shrawan through the end of Ashad of the following BS year. The value
  # carries the BS year in which it starts, so a date in months 1 to 3 belongs to the fiscal
  # year that started in the previous BS year (D-08).
  class FiscalYear
    include Comparable

    attr_reader :start_year

    def initialize(start_year)
      @start_year = Integer(start_year)
      freeze
    end

    def self.from(value)
      return value if value.is_a?(FiscalYear)

      new(value)
    end

    # The fiscal year containing +date+.
    def self.containing(date)
      raise TypeError, "expected a NepDate::Date, got #{date.class}" unless date.is_a?(Date)

      new((date.month >= 4) ? date.year : date.year - 1)
    end

    # 1 Shrawan of the fiscal year.
    def start
      Date.from_bs(start_year, 4, 1)
    end

    # The last day of Ashad of the following BS year.
    def end
      year = start_year + 1
      Date.from_bs(year, 3, Calendar.month_length(year, 3))
    end

    def range
      DateRange.new(start, self.end)
    end

    # The quarter +quarter+ of this fiscal year, clipped to the fiscal year's own bounds.
    def quarter_range(quarter)
      quarter = Quarter.from(quarter)
      start_month, start_offset, end_month, end_offset =
        case quarter.number
        when 1 then [4, 0, 6, 0]
        when 2 then [7, 0, 9, 0]
        when 3 then [10, 0, 12, 0]
        else [1, 1, 3, 1]
        end

      first = Date.from_bs(start_year + start_offset, start_month, 1)
      last_year = start_year + end_offset
      last = Date.from_bs(last_year, end_month, Calendar.month_length(last_year, end_month))
      DateRange.new(first, last)
    end

    def quarter_start(quarter)
      quarter_range(quarter).start
    end

    def quarter_end(quarter)
      quarter_range(quarter).end
    end

    # The label, "2081/82", with digits in +lang+.
    def label(lang: :en)
      lang = Lang.coerce(lang)
      "#{Names.digits(start_year, lang, width: 4)}/#{Names.digits((start_year + 1) % 100, lang, width: 2)}"
    end

    def succ
      FiscalYear.new(start_year + 1)
    end

    def <=>(other)
      return nil unless other.is_a?(FiscalYear)

      start_year <=> other.start_year
    end

    def ==(other)
      other.is_a?(FiscalYear) && start_year == other.start_year
    end
    alias_method :eql?, :==

    def hash
      [FiscalYear, start_year].hash
    end

    def to_s
      label
    end

    def inspect
      "#<NepDate::FiscalYear #{start_year}/#{(start_year + 1) % 100}>"
    end
  end
end
