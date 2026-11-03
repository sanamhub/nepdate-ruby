# frozen_string_literal: true

module NepDate
  # The rule that rejected a date, a parse or an arithmetic operation. The names match the
  # neutral error kinds of PARSING.md section 4; each is available as a symbol.
  module ErrorKind
    OUT_OF_RANGE = :out_of_range
    INVALID_MONTH = :invalid_month
    INVALID_DAY = :invalid_day
    INVALID_GREGORIAN = :invalid_gregorian
    INVALID_CHARACTER = :invalid_character
    WRONG_GROUP_COUNT = :wrong_group_count
    NUMBER_TOO_LONG = :number_too_long
    AMBIGUOUS = :ambiguous
    UNRECOGNIZED = :unrecognized

    ALL = [
      OUT_OF_RANGE, INVALID_MONTH, INVALID_DAY, INVALID_GREGORIAN,
      INVALID_CHARACTER, WRONG_GROUP_COUNT, NUMBER_TOO_LONG, AMBIGUOUS, UNRECOGNIZED
    ].freeze

    # The PascalCase spelling used by the shared vectors, for example +InvalidMonth+.
    def self.name_for(kind)
      kind.to_s.split("_").map(&:capitalize).join
    end
  end

  # Every failure this library raises. +kind+ says which rule failed, so callers match on the
  # symbol instead of the message.
  class Error < StandardError
    attr_reader :kind

    def initialize(kind, message)
      @kind = kind.to_sym
      super(message)
    end

    def kind_name
      ErrorKind.name_for(kind)
    end
  end

  # Raised when a parsed or constructed date, or an arithmetic result, is outside the supported
  # BS range.
  class OutOfRangeError < Error
    def initialize(message)
      super(ErrorKind::OUT_OF_RANGE, message)
    end
  end

  # Raised when a month number is outside 1 to 12.
  class InvalidMonthError < Error
    def initialize(message)
      super(ErrorKind::INVALID_MONTH, message)
    end
  end

  # Raised when a day number is outside the month.
  class InvalidDayError < Error
    def initialize(message)
      super(ErrorKind::INVALID_DAY, message)
    end
  end

  # Raised when an AD date is not a real Gregorian day.
  class InvalidGregorianError < Error
    def initialize(message)
      super(ErrorKind::INVALID_GREGORIAN, message)
    end
  end

  # Raised by strict and lenient parsing. +kind+ is the parse error kind from PARSING.md.
  class ParseError < Error
    def initialize(kind, message)
      super
    end
  end
end
