# frozen_string_literal: true

# Compiles shared/data/patro/*.json into the patro package's constant table (spec/PATRO.md
# section 3). JSON is read only here; the gem never reads a data file at runtime.
#
#   ruby scripts/generate_patro_tables.rb           regenerate
#   ruby scripts/generate_patro_tables.rb --check   fail if the committed file would change

require "json"

ROOT = File.expand_path("..", __dir__)
CALENDAR_PATH = File.join(ROOT, "shared/data/calendar/bs-calendar.json")
PATRO_DIR = File.join(ROOT, "shared/data/patro")
SUMMARY_PATH = File.join(ROOT, "shared/spec/vectors/patro-summary.json")
OUT_PATH = File.join(ROOT, "packages/nepdate-patro/lib/nepdate/patro/table.rb")

def fail_with(message)
  warn message
  exit 1
end

def read_json(path)
  JSON.parse(File.read(path, encoding: "UTF-8"))
rescue Errno::ENOENT, JSON::ParserError => e
  fail_with("cannot read #{path}: #{e.message}")
end

def build_calendar
  calendar = read_json(CALENDAR_PATH)
  min_year = calendar.fetch("min_year")
  max_year = calendar.fetch("max_year")
  lengths = calendar.fetch("month_lengths")
  year_start = {}
  month_length = {}
  cursor = 0
  (min_year..max_year).each do |year|
    year_start[year] = cursor
    month_length[year] = {}
    months = lengths.fetch(year.to_s)
    fail_with("year #{year} must have 12 months") unless months.length == 12
    months.each_with_index do |length, index|
      month_length[year][index + 1] = length
      cursor += length
    end
  end
  [year_start, month_length]
end

def serial_of(date_key, year_start, month_length)
  year, month, day = date_key.split("-").map { |part| Integer(part, 10) }
  serial = year_start.fetch(year)
  (1...month).each { |m| serial += month_length.fetch(year).fetch(m) }
  serial + day - 1
end

def generate
  year_start, month_length = build_calendar
  summary = read_json(SUMMARY_PATH)

  files = Dir[File.join(PATRO_DIR, "*.json")].sort
  fail_with("no patro files in #{PATRO_DIR}") if files.empty?

  name_index = {}
  names = []
  intern = lambda do |np, en|
    key = [np, en]
    unless name_index.key?(key)
      name_index[key] = names.length
      names << key
    end
    name_index.fetch(key)
  end

  tithi_by_serial = {}
  holiday_serials = []
  events_by_serial = {}
  tithi_names = []
  event_names = []
  source = nil

  files.each do |file|
    data = read_json(file)
    source = data["source"] if data["source"]
    days = data.fetch("days")
    days.each do |date_key, value|
      serial = serial_of(date_key, year_start, month_length)

      if value["tithi"]
        tithi = value.fetch("tithi")
        pair = [tithi.fetch("np"), tithi.fetch("en")]
        tithi_by_serial[serial] = intern.call(*pair)
        tithi_names << pair
      end
      holiday_serials << serial if value["holiday"]
      next unless value["events"]

      indices = []
      value.fetch("events").each do |event|
        pair = [event.fetch("np"), event.fetch("en")]
        indices << intern.call(*pair)
        event_names << pair
      end
      events_by_serial[serial] = indices
    end
  end

  tithi_by_serial = tithi_by_serial.sort.to_h
  events_by_serial = events_by_serial.sort.to_h
  holiday_serials.sort!

  all_serials = (tithi_by_serial.keys + holiday_serials + events_by_serial.keys).uniq.sort
  first_serial = all_serials.first
  last_serial = all_serials.last
  tithi_serials = tithi_by_serial.keys
  tithi_first = tithi_serials.first
  tithi_last = tithi_serials.last

  errors = []
  check = lambda do |label, actual, expected|
    errors << "#{label}: computed #{actual}, summary says #{expected}" unless actual == expected
  end
  check.call("days", last_serial - first_serial + 1, summary.fetch("days"))
  check.call("first_serial", first_serial, summary.fetch("first_serial"))
  check.call("last_serial", last_serial, summary.fetch("last_serial"))
  check.call("tithi_first_serial", tithi_first, summary.fetch("tithi_first_serial"))
  check.call("tithi_days", tithi_by_serial.length, summary.fetch("tithi_days"))
  check.call("tithi_names", tithi_names.uniq.length, summary.fetch("tithi_names"))
  check.call("holidays", holiday_serials.length, summary.fetch("holidays"))
  check.call("event_days", events_by_serial.length, summary.fetch("event_days"))
  check.call("events", events_by_serial.values.sum(&:length), summary.fetch("events"))
  check.call("event_names", event_names.uniq.length, summary.fetch("event_names"))
  check.call("names", names.length, summary.fetch("names"))
  check.call("name_bytes", names.sum { |np, en| np.bytesize + en.bytesize }, summary.fetch("name_bytes"))

  calendar = read_json(CALENDAR_PATH)
  first_day = first_bs_date(first_serial, calendar)
  last_day = last_bs_date(last_serial, calendar)
  check.call("first_day", first_day, summary.fetch("first_day"))
  check.call("last_day", last_day, summary.fetch("last_day"))
  check.call("tithi_first_day", first_bs_date(tithi_first, calendar), summary.fetch("tithi_first_day"))
  check.call("tithi_last_day", last_bs_date(tithi_last, calendar), summary.fetch("tithi_last_day"))

  (tithi_first..tithi_last).each do |serial|
    unless tithi_by_serial.key?(serial)
      errors << "tithi range has a gap at serial #{serial}"
      break
    end
  end

  if errors.any?
    warn "patro data disagrees with shared/spec/vectors/patro-summary.json:"
    errors.each { |error| warn "  - #{error}" }
    exit 1
  end

  tithi_index = (tithi_first..tithi_last).map { |serial| tithi_by_serial.fetch(serial) }
  event_day_serials = events_by_serial.keys
  event_start = [0]
  events_flat = []
  event_day_serials.each do |serial|
    events_by_serial.fetch(serial).each { |index| events_flat << index }
    event_start << events_flat.length
  end

  generated_from = if source
    "#{source.fetch("repo")} @ #{source.fetch("commit")[0, 12]}"
  else
    "shared/data/patro"
  end

  names_literal = names.map { |pair| "      [#{pair[0].inspect}, #{pair[1].inspect}].freeze" }.join(",\n")

  <<~RUBY
    # frozen_string_literal: true

    # DO NOT EDIT. Generated by scripts/generate_patro_tables.rb from
    # shared/data/patro/*.json (#{generated_from}), checked against
    # shared/spec/vectors/patro-summary.json. spec/PATRO.md section 3 defines the layout.

    module NepDate
      module Patro
        # The compiled patro tables. @api private
        module Table
          FIRST_SERIAL = #{first_serial}
          LAST_SERIAL = #{last_serial}

          TITHI_FIRST_SERIAL = #{tithi_first}
          TITHI_LAST_SERIAL = #{tithi_last}

          # One name index per day from TITHI_FIRST_SERIAL to TITHI_LAST_SERIAL.
          TITHI_INDEX = [
            #{tithi_index.each_slice(20).map { |slice| slice.join(", ") }.join(",\n    ")}
          ].freeze

          # Ascending serials with a gazetted public holiday.
          HOLIDAY_SERIALS = [
            #{holiday_serials.each_slice(20).map { |slice| slice.join(", ") }.join(",\n    ")}
          ].freeze

          # Ascending serials with one or more events.
          EVENT_DAY_SERIALS = [
            #{event_day_serials.each_slice(20).map { |slice| slice.join(", ") }.join(",\n    ")}
          ].freeze

          # CSR row pointers into EVENTS_FLAT, one more than EVENT_DAY_SERIALS.
          EVENT_START = [
            #{event_start.each_slice(20).map { |slice| slice.join(", ") }.join(",\n    ")}
          ].freeze

          # Name indices per event, in file order within a day.
          EVENTS_FLAT = [
            #{events_flat.each_slice(20).map { |slice| slice.join(", ") }.join(",\n    ")}
          ].freeze

          # Deduplicated (np, en) pairs shared by tithi and events.
          NAMES = [
    #{names_literal}
          ].freeze
        end
      end
    end
  RUBY
end

def first_bs_date(serial, calendar)
  civil = civil_from_serial(serial, calendar)
  format("%04d-%02d-%02d", *civil)
end

def last_bs_date(serial, calendar)
  first_bs_date(serial, calendar)
end

def civil_from_serial(serial, calendar)
  year_start = {}
  cursor = 0
  (calendar.fetch("min_year")..calendar.fetch("max_year")).each do |year|
    year_start[year] = cursor
    cursor += calendar.fetch("month_lengths").fetch(year.to_s).sum
  end
  year = year_start.keys.reverse.find { |candidate| year_start.fetch(candidate) <= serial }
  remaining = serial - year_start.fetch(year)
  month = 1
  lengths = calendar.fetch("month_lengths").fetch(year.to_s)
  while remaining >= lengths[month - 1]
    remaining -= lengths[month - 1]
    month += 1
  end
  [year, month, remaining + 1]
end

generated = generate

if ARGV.include?("--check")
  current = File.exist?(OUT_PATH) ? File.read(OUT_PATH, encoding: "UTF-8") : nil
  if current != generated
    warn "packages/nepdate-patro/lib/nepdate/patro/table.rb is out of date; run: ruby scripts/generate_patro_tables.rb"
    exit 1
  end
  puts "packages/nepdate-patro/lib/nepdate/patro/table.rb matches shared/data/patro/*.json"
else
  File.write(OUT_PATH, generated, encoding: "UTF-8")
  puts "wrote packages/nepdate-patro/lib/nepdate/patro/table.rb"
end
