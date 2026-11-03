# frozen_string_literal: true

module NepDate
  # Formatting for every public form (FORMATTING.md sections 2 to 5). One pass, no regular
  # expressions in the pattern formatter.
  # @api private
  module Format
    DEFAULT_PATTERNS = ["", "G", "g", "d"].freeze

    module_function

    def default(year, month, day, lang)
      lang = Lang.coerce(lang)
      [
        Names.digits(year, lang, width: 4),
        Names.digits(month, lang, width: 2),
        Names.digits(day, lang, width: 2)
      ].join("/")
    end

    def iso8601(year, month, day, lang)
      lang = Lang.coerce(lang)
      [
        Names.digits(year, lang, width: 4),
        Names.digits(month, lang, width: 2),
        Names.digits(day, lang, width: 2)
      ].join("-")
    end

    def short(year, month, day, order:, separator:, pad:, lang:)
      lang = Lang.coerce(lang)
      fields = DateOrder.fields(order)
      separator = Separator.character(separator)
      values = {
        year: Names.digits(year, lang, width: 4),
        month: Names.digits(month, lang, width: pad ? 2 : 0),
        day: Names.digits(day, lang, width: pad ? 2 : 0)
      }

      fields.map { |field| values.fetch(field) }.join(separator)
    end

    def long(year, month, day, weekday_number:, include_year:, pad:, lang:)
      lang = Lang.coerce(lang)
      day_text = Names.digits(day, lang, width: pad ? 2 : 0)
      year_text = Names.digits(year, lang, width: 4)
      prefix = weekday_number.nil? ? "" : "#{Names.weekday_name(weekday_number, lang)}, "
      suffix = include_year ? ", #{year_text}" : ""

      "#{prefix}#{Names.month_name(month, lang)} #{day_text}#{suffix}"
    end

    def pattern(pattern, year:, month:, day:, lang:)
      raise TypeError, "format pattern must be a String, got #{pattern.class}" unless pattern.is_a?(String)

      lang = Lang.coerce(lang)
      return default(year, month, day, lang) if DEFAULT_PATTERNS.include?(pattern)
      return long(year, month, day, weekday_number: nil, include_year: true, pad: true, lang: lang) if pattern == "D"
      return iso8601(year, month, day, lang) if pattern == "s"

      tokens = {
        year: Names.digits(year, lang, width: 4),
        year2: Names.digits(year % 100, lang, width: 2),
        month_name: Names.month_name(month, lang),
        month_short: Names.month_short(month, lang),
        month_pad: Names.digits(month, lang, width: 2),
        month: Names.digits(month, lang),
        day_pad: Names.digits(day, lang, width: 2),
        day: Names.digits(day, lang)
      }

      out = +""
      chars = pattern.chars
      index = 0
      while index < chars.length
        char = chars[index]
        if char == "\\"
          # A trailing backslash has nothing to escape, so it is written literally.
          out << ((index + 1 < chars.length) ? chars[index + 1] : "\\")
          index += 2
          next
        end

        if char == "'"
          closing = ((index + 1)...chars.length).find { |position| chars[position] == "'" }
          if closing
            out << chars[(index + 1)...closing].join
            index = closing + 1
          else
            out << chars[(index + 1)..].join
            break
          end
          next
        end

        if char == "y"
          finish = run_end(chars, index, "y")
          out << ((finish - index >= 4) ? tokens[:year] : tokens[:year2])
          index = finish
          next
        end

        if char == "M"
          finish = run_end(chars, index, "M")
          length = finish - index
          value = if length >= 4
            tokens[:month_name]
          elsif length == 3
            tokens[:month_short]
          elsif length == 2
            tokens[:month_pad]
          else
            tokens[:month]
          end
          out << value
          index = finish
          next
        end

        if char == "d"
          finish = run_end(chars, index, "d")
          out << ((finish - index == 2) ? tokens[:day_pad] : tokens[:day])
          index = finish
          next
        end

        out << char
        index += 1
      end

      out
    end

    def run_end(chars, index, char)
      finish = index + 1
      finish += 1 while finish < chars.length && chars[finish] == char
      finish
    end
  end
end
