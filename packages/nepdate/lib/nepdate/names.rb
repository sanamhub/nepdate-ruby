# frozen_string_literal: true

module NepDate
  # The month, weekday and digit names of FORMATTING.md section 1.
  # @api private
  module Names
    MONTH_EN = [
      "", "Baishakh", "Jestha", "Ashad", "Shrawan", "Bhadra", "Ashoj",
      "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra"
    ].freeze

    MONTH_NE = [
      "", "बैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज",
      "कार्तिक", "मंसिर", "पुष", "माघ", "फागुन", "चैत"
    ].freeze

    # D-04: Ashad and Ashoj are Asa and Aso, not the C# "Ash" shared by both.
    MONTH_SHORT_EN = [
      "", "Bai", "Jes", "Asa", "Shr", "Bha", "Aso",
      "Kar", "Man", "Pou", "Mag", "Fal", "Cha"
    ].freeze

    WEEKDAY_EN = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
    WEEKDAY_NE = %w[आइतवार सोमवार मङ्गलवार बुधवार बिहिवार शुक्रवार शनिवार].freeze
    WEEKDAY_SHORT_EN = %w[Sun Mon Tue Wed Thu Fri Sat].freeze
    WEEKDAY_SHORT_NE = %w[आइत सोम मङ्गल बुध बिहि शुक्र शनि].freeze

    DEVANAGARI_DIGITS = %w[० १ २ ३ ४ ५ ६ ७ ८ ९].freeze
    ASCII_DIGITS = %w[0 1 2 3 4 5 6 7 8 9].freeze

    def self.month_name(number, lang = :en)
      (lang == :ne) ? MONTH_NE.fetch(number) : MONTH_EN.fetch(number)
    end

    def self.month_short(number, lang = :en)
      return MONTH_NE.fetch(number) if lang == :ne

      MONTH_SHORT_EN.fetch(number)
    end

    def self.weekday_name(number, lang = :en)
      (lang == :ne) ? WEEKDAY_NE.fetch(number) : WEEKDAY_EN.fetch(number)
    end

    def self.weekday_short(number, lang = :en)
      (lang == :ne) ? WEEKDAY_SHORT_NE.fetch(number) : WEEKDAY_SHORT_EN.fetch(number)
    end

    # Replaces every ASCII digit with its Devanagari counterpart and leaves every other character
    # alone (FORMATTING.md section 1).
    def self.nepali_digits(text)
      text.tr("0123456789", "०१२३४५६७८९")
    end

    def self.digits(number, lang = :en, width: 0)
      if width == 4 && number >= CalendarTable::MIN_YEAR && number <= CalendarTable::MAX_YEAR
        return (lang == :ne) ? YEAR_NE[number - CalendarTable::MIN_YEAR] : YEAR_EN[number - CalendarTable::MIN_YEAR]
      end
      if width == 2 && number >= 0 && number <= 99
        return (lang == :ne) ? TWO_DIGIT_NE[number] : TWO_DIGIT_EN[number]
      end
      if width.zero? && number >= 0 && number <= 99
        return (lang == :ne) ? NUMBER_NE[number] : NUMBER_EN[number]
      end

      text = number.to_s
      text = text.rjust(width, "0") if width.positive?
      (lang == :ne) ? nepali_digits(text) : text
    end

    # The short and long forms of every digit string the formatters need, built once at load so a
    # formatting call only reads a String. Years are 1901 through 2199; the two-digit and plain
    # tables cover dates, months and the two-digit year.
    NUMBER_EN = (0..99).map(&:to_s).freeze
    NUMBER_NE = NUMBER_EN.map { |text| nepali_digits(text) }.freeze
    TWO_DIGIT_EN = (0..99).map { |number| number.to_s.rjust(2, "0") }.freeze
    TWO_DIGIT_NE = TWO_DIGIT_EN.map { |text| nepali_digits(text) }.freeze
    YEAR_EN = (CalendarTable::MIN_YEAR..CalendarTable::MAX_YEAR).map(&:to_s).freeze
    YEAR_NE = YEAR_EN.map { |text| nepali_digits(text) }.freeze
  end
end
