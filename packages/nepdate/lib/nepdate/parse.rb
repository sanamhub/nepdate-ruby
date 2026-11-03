# frozen_string_literal: true

module NepDate
  # The strict parser of PARSING.md section 1: year, month, day, with ASCII and Devanagari
  # digits mixed freely. The scanner walks UTF-8 bytes; the only multi-byte characters it accepts
  # are the ten Devanagari digits and the danda separator.
  # @api private
  module Parse
    GROUP_COUNT = 3
    MAX_DIGITS = 4
    SEPARATOR_BYTES = {
      0x2D => true, 0x2F => true, 0x2E => true, 0x5F => true,
      0x5C => true, 0x20 => true, 0x7C => true
    }.freeze
    DANDA = "।"

    module_function

    def strict(text)
      raise TypeError, "date text must be a String, got #{text.class}" unless text.is_a?(String)

      groups = [0, 0, 0]
      count = 0
      in_group = false
      digits = 0
      index = 0
      length = text.bytesize

      while index < length
        byte = text.getbyte(index)
        digit = nil
        separator = false
        width = 1

        if byte.between?(0x30, 0x39)
          digit = byte - 0x30
        elsif byte < 0x80
          separator = SEPARATOR_BYTES.key?(byte)
          invalid_character(text, index) unless separator
        elsif byte == 0xE0
          second = text.getbyte(index + 1)
          third = text.getbyte(index + 2)
          if second == 0xA5 && third
            if third.between?(0xA6, 0xAF)
              digit = third - 0xA6
              width = 3
            elsif third == 0xA4
              separator = true
              width = 3
            else
              invalid_character(text, index)
            end
          else
            invalid_character(text, index)
          end
        else
          invalid_character(text, index)
        end

        if digit
          if !in_group
            if count == GROUP_COUNT
              raise ParseError.new(ErrorKind::WRONG_GROUP_COUNT, "more than three groups")
            end
            count += 1
            in_group = true
            digits = 0
          end
          digits += 1
          if digits > MAX_DIGITS
            raise ParseError.new(ErrorKind::NUMBER_TOO_LONG, "a group has more than 4 digits")
          end
          groups[count - 1] = groups[count - 1] * 10 + digit
          index += width
          next
        end

        in_group = false
        index += width
      end

      if count < GROUP_COUNT
        raise ParseError.new(ErrorKind::WRONG_GROUP_COUNT, "fewer than three groups")
      end

      groups
    end

    def invalid_character(text, index)
      char = text.byteslice(index, 4).to_s.each_char.first
      raise ParseError.new(ErrorKind::INVALID_CHARACTER, "invalid character #{char.inspect}")
    end
  end
end
