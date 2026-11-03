# frozen_string_literal: true

module NepDate
  # A weekday with Sunday = 0, the numbering of ALGORITHM.md section 7 and the shared vectors.
  class Weekday
    include Comparable

    attr_reader :number

    def initialize(number)
      number = Integer(number)
      unless (0..6).cover?(number)
        raise ArgumentError, "weekday #{number} is outside 0..6"
      end

      @number = number
      freeze
    end

    def self.from(value)
      return value if value.is_a?(Weekday)

      new(value)
    end

    SUNDAY = new(0)
    MONDAY = new(1)
    TUESDAY = new(2)
    WEDNESDAY = new(3)
    THURSDAY = new(4)
    FRIDAY = new(5)
    SATURDAY = new(6)

    ALL = [SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY].freeze

    def label(lang: :en)
      Names.weekday_name(number, Lang.coerce(lang))
    end

    def short_label(lang: :en)
      Names.weekday_short(number, Lang.coerce(lang))
    end

    def sunday? = number.zero?

    def monday? = number == 1

    def tuesday? = number == 2

    def wednesday? = number == 3

    def thursday? = number == 4

    def friday? = number == 5

    def saturday? = number == 6

    def to_i
      number
    end

    def to_s
      label
    end

    def <=>(other)
      return nil unless other.is_a?(Weekday)

      number <=> other.number
    end

    def ==(other)
      other.is_a?(Weekday) && number == other.number
    end
    alias_method :eql?, :==

    def hash
      [Weekday, number].hash
    end

    def inspect
      "#<NepDate::Weekday #{number} #{label}>"
    end
  end
end
