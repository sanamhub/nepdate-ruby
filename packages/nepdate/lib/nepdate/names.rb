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
      text = number.to_s
      text = text.rjust(width, "0") if width.positive?
      (lang == :ne) ? nepali_digits(text) : text
    end
  end
end
