# frozen_string_literal: true

module NepDate
  # What whole-month arithmetic does when the day does not exist in the target month (D-02).
  # +:clamp+ keeps the last day of the target month; +:spill+ moves the excess into the next
  # month. There is no fractional month arithmetic.
  module MonthOverflow
    CLAMP = :clamp
    SPILL = :spill
    ALL = [CLAMP, SPILL].freeze

    def self.coerce(value)
      return value if value == CLAMP || value == SPILL

      symbol = value.to_s.downcase.to_sym
      return symbol if ALL.include?(symbol)

      raise ArgumentError, "overflow must be :clamp or :spill, got #{value.inspect}"
    end
  end
end
