# frozen_string_literal: true

require_relative "nepdate/version"
require_relative "nepdate/errors"
require_relative "nepdate/calendar_table"
require_relative "nepdate/calendar"
require_relative "nepdate/names"
require_relative "nepdate/lang"
require_relative "nepdate/month"
require_relative "nepdate/weekday"
require_relative "nepdate/quarter"
require_relative "nepdate/format_options"
require_relative "nepdate/month_overflow"
require_relative "nepdate/date_diff"
require_relative "nepdate/parse"
require_relative "nepdate/lenient"
require_relative "nepdate/format"
require_relative "nepdate/date"
require_relative "nepdate/date_range"
require_relative "nepdate/fiscal_year"

# Bikram Sambat dates for Ruby. The canonical entry point is +NepDate::Date+;
# +NepDate::Date.parse+ reads a strict date and +NepDate::Date.today+ reads the clock through an
# explicit zone and an optional injected clock.
module NepDate
  class << self
    # The date +text+ names, with the strict grammar.
    def parse(text)
      Date.parse(text)
    end

    # Today in +zone+, with an optional clock callable.
    def today(zone: Date::DEFAULT_ZONE, clock: nil)
      Date.today(zone: zone, clock: clock)
    end
  end
end
