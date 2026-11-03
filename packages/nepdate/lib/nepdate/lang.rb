# frozen_string_literal: true

module NepDate
  # The output language: +:en+ for English, +:ne+ for Nepali. Symbols are the Ruby spelling of
  # the C# +Lang+ option used by the other ports.
  module Lang
    EN = :en
    NE = :ne

    def self.coerce(value)
      case value
      when :en, "en" then EN
      when :ne, "ne" then NE
      else
        raise ArgumentError, "language must be :en or :ne, got #{value.inspect}"
      end
    end
  end
end
