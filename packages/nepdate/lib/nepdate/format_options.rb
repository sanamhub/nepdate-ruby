# frozen_string_literal: true

module NepDate
  # The field order of short and range formatting (FORMATTING.md section 3). Use the symbols
  # +:ymd+, +:ydm+, +:myd+, +:mdy+, +:dym+ or +:dmy+.
  module DateOrder
    ORDER = {
      ymd: [:year, :month, :day],
      ydm: [:year, :day, :month],
      myd: [:month, :year, :day],
      mdy: [:month, :day, :year],
      dym: [:day, :year, :month],
      dmy: [:day, :month, :year]
    }.freeze

    ALL = ORDER.keys.freeze

    def self.coerce(value)
      symbol = value.to_s.downcase.to_sym
      return symbol if ORDER.key?(symbol)

      raise ArgumentError, "date order must be one of #{ALL.join(", ")}, got #{value.inspect}"
    end

    def self.fields(value)
      ORDER.fetch(coerce(value))
    end
  end

  # The separator of short and range formatting (FORMATTING.md section 3). Use +:slash+,
  # +:backslash+, +:dot+, +:underscore+, +:dash+ or +:space+, or pass the character itself.
  module Separator
    CHARACTERS = {
      slash: "/",
      backslash: "\\",
      dot: ".",
      underscore: "_",
      dash: "-",
      space: " "
    }.freeze

    ALL = CHARACTERS.keys.freeze
    BY_CHARACTER = CHARACTERS.invert.freeze

    def self.coerce(value)
      return BY_CHARACTER.fetch(value) if CHARACTERS.value?(value)

      symbol = value.to_s.downcase.to_sym
      return symbol if CHARACTERS.key?(symbol)

      raise ArgumentError, "separator must be one of #{ALL.join(", ")}, got #{value.inspect}"
    end

    def self.character(value)
      return value if CHARACTERS.value?(value)

      CHARACTERS.fetch(coerce(value))
    end

    def self.name_for(character)
      BY_CHARACTER.fetch(character)
    end
  end
end
