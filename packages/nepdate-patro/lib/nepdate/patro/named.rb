# frozen_string_literal: true

module NepDate
  module Patro
    # A tithi or event name in both languages. +name+ selects one; +nepali+ and +english+ are
    # always available.
    class Named
      attr_reader :nepali, :english

      def initialize(nepali, english)
        @nepali = String(nepali).freeze
        @english = String(english).freeze
        freeze
      end

      def name(lang: :en)
        (Lang.coerce(lang) == :ne) ? nepali : english
      end

      def to_h
        {np: nepali, en: english}
      end

      def ==(other)
        other.is_a?(self.class) && nepali == other.nepali && english == other.english
      end
      alias_method :eql?, :==

      def hash
        [self.class, nepali, english].hash
      end

      def to_s
        english
      end

      def inspect
        "#<#{self.class} #{english.inspect} / #{nepali.inspect}>"
      end
    end

    # A lunar day name.
    class Tithi < Named
    end

    # One almanac event, in file order when several share a day.
    class Event < Named
    end
  end
end
