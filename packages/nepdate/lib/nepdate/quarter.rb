# frozen_string_literal: true

module NepDate
  # A fiscal quarter: Q1 Shrawan-Ashoj through Q4 Baishakh-Ashad of the following year.
  class Quarter
    include Comparable

    NAMES = {1 => :q1, 2 => :q2, 3 => :q3, 4 => :q4}.freeze
    LABELS = {1 => "Q1", 2 => "Q2", 3 => "Q3", 4 => "Q4"}.freeze

    attr_reader :number

    def initialize(number)
      number = Integer(number)
      unless (1..4).cover?(number)
        raise ArgumentError, "quarter #{number} is outside 1..4"
      end

      @number = number
      freeze
    end

    def self.from(value)
      return value if value.is_a?(Quarter)

      case value
      when :q1, "q1", 1 then Q1
      when :q2, "q2", 2 then Q2
      when :q3, "q3", 3 then Q3
      when :q4, "q4", 4 then Q4
      else
        raise ArgumentError, "quarter must be 1..4 or :q1..:q4, got #{value.inspect}"
      end
    end

    Q1 = new(1)
    Q2 = new(2)
    Q3 = new(3)
    Q4 = new(4)

    ALL = [Q1, Q2, Q3, Q4].freeze

    def name
      NAMES.fetch(number)
    end

    def label
      LABELS.fetch(number)
    end

    def to_i
      number
    end

    def to_s
      label
    end

    def <=>(other)
      return nil unless other.is_a?(Quarter)

      number <=> other.number
    end

    def ==(other)
      other.is_a?(Quarter) && number == other.number
    end
    alias_method :eql?, :==

    def hash
      [Quarter, number].hash
    end

    def inspect
      "#<NepDate::Quarter #{label}>"
    end
  end
end
