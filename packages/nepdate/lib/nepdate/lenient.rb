# frozen_string_literal: true

module NepDate
  # The deterministic human-input parser of PARSING.md section 2. It tries the strict grammar
  # first, then a closed token grammar with a fixed month-name list. It never guesses.
  # @api private
  module Lenient
    SEPARATORS = ["-", "/", "\\", "_", " ", "|", "।", ","].freeze
    MAX_DIGITS = 4
    KELVIN = "\u212A"

    DEVA_DIGITS = {
      "०" => "0", "१" => "1", "२" => "2", "३" => "3", "४" => "4",
      "५" => "5", "६" => "6", "७" => "7", "८" => "8", "९" => "9"
    }.freeze

    ERA_MARKERS = ["bs", "b.s.", "b.s", "vs", "v.s.", "v.s", "बि.सं.", "वि.सं.", "बि.सं", "वि.सं"].freeze
    IGNORED_WORDS = ["गते", "मिति"].freeze

    MONTH_WORDS = {
      "baishakh" => 1, "baisakh" => 1, "baishak" => 1, "vaishakh" => 1, "vaisakh" => 1, "bai" => 1,
      "बैशाख" => 1, "वैशाख" => 1, "बैसाख" => 1,
      "jestha" => 2, "jeth" => 2, "jyestha" => 2, "jes" => 2,
      "जेठ" => 2, "जेष्ठ" => 2, "ज्येष्ठ" => 2,
      "ashad" => 3, "ashadh" => 3, "asar" => 3, "asadh" => 3, "asa" => 3,
      "असार" => 3, "आषाढ" => 3, "असाढ" => 3,
      "shrawan" => 4, "shravan" => 4, "srawan" => 4, "sawan" => 4, "saun" => 4, "shr" => 4,
      "साउन" => 4, "श्रावण" => 4, "सावन" => 4,
      "bhadra" => 5, "bhadau" => 5, "bha" => 5,
      "भदौ" => 5, "भाद्र" => 5, "भाद्रपद" => 5,
      "ashoj" => 6, "asoj" => 6, "ashwin" => 6, "aso" => 6,
      "असोज" => 6, "आश्विन" => 6, "असौज" => 6,
      "kartik" => 7, "kattik" => 7, "kar" => 7,
      "कार्तिक" => 7, "कात्तिक" => 7,
      "mangsir" => 8, "mansir" => 8, "margashirsha" => 8, "man" => 8,
      "मंसिर" => 8, "मङ्सिर" => 8, "मार्गशीर्ष" => 8,
      "poush" => 9, "paush" => 9, "push" => 9, "pus" => 9, "pou" => 9,
      "पुष" => 9, "पौष" => 9, "पुस" => 9,
      "magh" => 10, "mag" => 10, "माघ" => 10,
      "falgun" => 11, "phalgun" => 11, "fagun" => 11, "fal" => 11,
      "फागुन" => 11, "फाल्गुन" => 11,
      "chaitra" => 12, "chait" => 12, "cha" => 12,
      "चैत" => 12, "चैत्र" => 12
    }.freeze

    module_function

    def parse(text)
      begin
        strict = Parse.strict(text)
        Calendar.validate(*strict)
        return strict
      rescue Error
        # The strict grammar or the date it reads is unusable: try the token grammar.
      end

      normalized = text.each_char.map { |char| DEVA_DIGITS.fetch(char, char) }.join
      numbers, digit_counts, months, unknown = tokens(normalized)

      if unknown
        raise ParseError.new(ErrorKind::UNRECOGNIZED, "unknown word")
      end
      if months.length >= 2
        raise ParseError.new(ErrorKind::UNRECOGNIZED, "more than one month name")
      end
      if months.length == 1 && numbers.length == 2
        return month_form(months.first, numbers, digit_counts)
      end
      if months.empty? && numbers.length == 3
        return numeric_form(numbers, digit_counts)
      end

      raise ParseError.new(ErrorKind::UNRECOGNIZED, "unrecognized token count")
    end

    # [numbers, digit counts, month numbers, saw an unknown word]
    def tokens(text)
      numbers = []
      digit_counts = []
      months = []
      unknown = false

      index = 0
      chars = text.chars
      while index < chars.length
        char = chars[index]
        if SEPARATORS.include?(char)
          index += 1
          next
        end

        chunk = +""
        while index < chars.length
          char = chars[index]
          break if SEPARATORS.include?(char)

          chunk << char
          index += 1
        end

        if numeric?(chunk)
          chunk.split(".").each do |part|
            next if part.empty?
            if part.length > MAX_DIGITS
              raise ParseError.new(ErrorKind::NUMBER_TOO_LONG, "a number has more than 4 digits")
            end

            numbers << part.to_i
            digit_counts << part.length
          end
          next
        end

        value = word_value(chunk)
        if value.positive?
          months << value
        elsif value.negative?
          unknown = true
        end
      end

      [numbers, digit_counts, months, unknown]
    end

    def numeric?(chunk)
      chunk.each_char.all? { |char| char.between?("0", "9") || char == "." }
    end

    # A month number, 0 for a dropped marker, or -1 for an unknown word.
    def word_value(token)
      folded = fold(token)
      month = MONTH_WORDS[folded]
      return month if month
      return 0 if ERA_MARKERS.include?(folded) || IGNORED_WORDS.include?(folded)

      -1
    end

    # Exactly ASCII A-Z plus the Kelvin sign fold; no other character changes (PARSING.md).
    def fold(token)
      token.each_char.map { |char|
        if char.between?("A", "Z")
          (char.ord + 32).chr(Encoding::UTF_8)
        elsif char == KELVIN
          "k"
        else
          char
        end
      }.join
    end

    def month_form(month, numbers, digit_counts)
      four = []
      digit_counts.each_with_index { |count, index| four << index if count == MAX_DIGITS }
      unless four.length == 1
        raise ParseError.new(ErrorKind::AMBIGUOUS, "no single four-digit year")
      end

      year_index = four.first
      other_index = 1 - year_index
      if digit_counts[other_index] > 2
        raise ParseError.new(ErrorKind::AMBIGUOUS, "the day has more than two digits")
      end

      [numbers[year_index], month, numbers[other_index]]
    end

    def numeric_form(numbers, digit_counts)
      return [numbers[0], numbers[1], numbers[2]] if digit_counts[0] == MAX_DIGITS
      return [numbers[2], numbers[1], numbers[0]] if digit_counts[2] == MAX_DIGITS

      raise ParseError.new(ErrorKind::AMBIGUOUS, "no four-digit year first or last")
    end
  end
end
