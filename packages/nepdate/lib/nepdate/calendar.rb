# frozen_string_literal: true

module NepDate
  # BS serial arithmetic and the proleptic Gregorian conversion of ALGORITHM.md sections 3 to 6.
  # @api private
  module Calendar
    GREGORIAN_MONTH_LENGTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

    module_function

    def month_length(year, month)
      index = year - CalendarTable::MIN_YEAR
      unless index >= 0 && index < CalendarTable::YEARS
        raise OutOfRangeError, "year #{year} is outside #{CalendarTable::MIN_YEAR}..#{CalendarTable::MAX_YEAR}"
      end
      unless month.between?(1, 12)
        raise InvalidMonthError, "month #{month} is outside 1..12"
      end

      packed = CalendarTable::PACKED.fetch(index)
      29 + ((packed >> (2 * (month - 1))) & 0b11)
    end

    def to_serial(year, month, day)
      CalendarTable::MONTH_START.fetch((year - CalendarTable::MIN_YEAR) * 12 + month - 1) + day - 1
    end

    def validate(year, month, day)
      unless year.between?(CalendarTable::MIN_YEAR, CalendarTable::MAX_YEAR)
        raise OutOfRangeError, "year #{year} is outside #{CalendarTable::MIN_YEAR}..#{CalendarTable::MAX_YEAR}"
      end
      unless month.between?(1, 12)
        raise InvalidMonthError, "month #{month} is outside 1..12"
      end

      length = month_length(year, month)
      unless day.between?(1, length)
        raise InvalidDayError, "day #{day} is outside 1..#{length}"
      end

      true
    end

    # Proleptic Gregorian civil date to days since 1970-01-01, by Howard Hinnant's algorithm.
    def days_from_civil(year, month, day)
      year -= 1 if month <= 2
      era = year.div(400)
      year_of_era = year - era * 400
      month_prime = (month + 9) % 12
      day_of_year = (153 * month_prime + 2) / 5 + day - 1
      day_of_era = year_of_era * 365 + year_of_era / 4 - year_of_era / 100 + day_of_year
      era * 146097 + day_of_era - 719_468
    end

    def civil_from_days(days)
      days += 719_468
      era = days.div(146_097)
      day_of_era = days - era * 146_097
      year_of_era = (day_of_era - day_of_era / 1460 + day_of_era / 36_524 - day_of_era / 146_096) / 365
      year = year_of_era + era * 400
      day_of_year = day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100)
      month_prime = (5 * day_of_year + 2) / 153
      day = day_of_year - (153 * month_prime + 2) / 5 + 1
      month = (month_prime < 10) ? month_prime + 3 : month_prime - 9
      year += 1 if month <= 2
      [year, month, day]
    end

    def gregorian_month_length(year, month)
      return 29 if month == 2 && gregorian_leap_year?(year)

      GREGORIAN_MONTH_LENGTHS.fetch(month - 1)
    end

    def gregorian_leap_year?(year)
      (year % 4).zero? && !(year % 100).zero? || (year % 400).zero?
    end

    def valid_gregorian?(year, month, day)
      return false unless (1..12).cover?(month)

      (1..gregorian_month_length(year, month)).cover?(day)
    end
  end
end
