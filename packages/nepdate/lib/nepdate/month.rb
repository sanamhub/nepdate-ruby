# frozen_string_literal: true

module NepDate
  # A Bikram Sambat month, 1 = Baishakh through 12 = Chaitra. Ruby has no enum, so this is a
  # small immutable value with the twelve members as constants.
  class Month
    include Comparable

    NAMES_EN = Names::MONTH_EN
    NAMES_NE = Names::MONTH_NE
    SHORT_EN = Names::MONTH_SHORT_EN

    attr_reader :number

    def initialize(number)
      number = Integer(number)
      unless (1..12).cover?(number)
        raise InvalidMonthError, "month #{number} is outside 1..12"
      end

      @number = number
      freeze
    end

    def self.from(value)
      return value if value.is_a?(Month)

      new(value)
    end

    BAISHAKH = new(1)
    JESTHA = new(2)
    ASHAD = new(3)
    SHRAWAN = new(4)
    BHADRA = new(5)
    ASHOJ = new(6)
    KARTIK = new(7)
    MANGSIR = new(8)
    POUSH = new(9)
    MAGH = new(10)
    FALGUN = new(11)
    CHAITRA = new(12)

    ALL = [
      BAISHAKH, JESTHA, ASHAD, SHRAWAN, BHADRA, ASHOJ,
      KARTIK, MANGSIR, POUSH, MAGH, FALGUN, CHAITRA
    ].freeze

    def label(lang: :en)
      Names.month_name(number, Lang.coerce(lang))
    end

    def short_label(lang: :en)
      Names.month_short(number, Lang.coerce(lang))
    end

    def to_i
      number
    end

    def to_s
      label
    end

    def <=>(other)
      return nil unless other.is_a?(Month)

      number <=> other.number
    end

    def ==(other)
      other.is_a?(Month) && number == other.number
    end
    alias_method :eql?, :==

    def hash
      [Month, number].hash
    end

    def inspect
      "#<NepDate::Month #{number} #{label}>"
    end
  end
end
