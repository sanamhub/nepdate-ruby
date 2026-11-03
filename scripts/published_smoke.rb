# frozen_string_literal: true

# Checks the gems installed from RubyGems, not the working tree. Used by release.yml and
# verify-published.yml after `gem install`.

require "nepdate"
require "nepdate/patro"

require "rubygems"

version = ARGV.fetch(0, NepDate::VERSION)
expected = Gem::Version.new(version)
raise "core version is #{NepDate::VERSION}, expected #{version}" unless Gem::Version.new(NepDate::VERSION) == expected
unless Gem::Version.new(NepDate::Patro::VERSION) == expected
  raise "patro version is #{NepDate::Patro::VERSION}, expected #{version}"
end

date = NepDate::Date.parse("2081-04-15")
raise "wrong conversion" unless date.to_date.iso8601 == "2024-07-30"
raise "wrong long form" unless date.to_long_string(weekday: true) == "Tuesday, Shrawan 15, 2081"
raise "wrong ymd" unless NepDate::Date.from_ymd(date.to_ymd) == date
raise "wrong round trip" unless NepDate::Date.from_json(date.to_json) == date

patro_date = NepDate::Date.parse("2081-02-15")
info = NepDate::Patro.info(patro_date)
raise "wrong tithi" unless info.tithi_en == "Panchami"
raise "wrong holiday" unless info.public_holiday?
raise "wrong events" unless info.events_en == ["Republic Day"]
raise "wrong coverage" unless NepDate::Patro.coverage.start.iso8601 == "2077-01-01"

puts "nepdate #{version}: installed gems convert a date and read a patro event"
