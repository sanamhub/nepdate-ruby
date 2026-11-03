# frozen_string_literal: true

require_relative "../test_helper"
require "json"

# spec/PATRO.md section 4 anchors, the summary counts, and an exhaustive comparison against the
# shared JSON for every covered day.
class PatroTest < Minitest::Test
  SUMMARY = JSON.parse(File.read(File.expand_path("../../shared/spec/vectors/patro-summary.json", __dir__)))
  PATRO_DIR = File.expand_path("../../shared/data/patro", __dir__)

  def test_anchor_days
    new_year = info("2081-01-01")
    assert_equal "Panchami", new_year.tithi_en
    assert_equal "पञ्चमी", new_year.tithi_np
    assert new_year.public_holiday?
    assert_equal ["New Year", "Mesh Sankranti", "Bisket Jatra"], new_year.events_en
    assert_equal ["नयाँ वर्ष", "मेष संक्रान्ति", "बिस्का: जात्रा"], new_year.events_np

    assert_equal "Shashthi", info("2081-01-02").tithi_en
    refute info("2081-01-02").public_holiday?
    assert_empty info("2081-01-02").events_en

    republic = info("2081-02-15")
    assert_equal "Panchami", republic.tithi_en
    assert republic.public_holiday?
    assert_equal ["Republic Day"], republic.events_en

    assert_equal 5, info("2080-11-01").events_en.length
    assert_equal 3, info("2081-04-15").events_en.length
    refute info("2081-04-15").public_holiday?
    assert_empty info("2070-06-15").events_en
    assert_nil info("2070-06-15").tithi
    assert_empty info("2090-01-01").events_en
    assert_nil info("2090-01-01").tithi
  end

  def test_coverage_and_public_holidays
    coverage = NepDate::Patro.coverage
    assert_equal SUMMARY["first_day"], coverage.start.iso8601
    assert_equal SUMMARY["last_day"], coverage.end.iso8601
    assert_equal SUMMARY["days"], coverage.length
    holidays = NepDate::Patro.public_holidays
    assert_equal SUMMARY["holidays"], holidays.length
    assert_equal holidays.sort, holidays
    assert holidays.all? { |date| NepDate::Patro.info(date).public_holiday? }
    assert_nil holidays.find { |date| !coverage.include?(date) }
  end

  def test_summary_counts_match_the_public_surface
    tithi_days = 0
    holiday_days = 0
    event_days = 0
    events = 0
    tithi_names = {}
    event_names = {}

    NepDate::Patro.coverage.each do |date|
      info = NepDate::Patro.info(date)
      tithi_days += 1 if info.tithi
      tithi_names[[info.tithi.nepali, info.tithi.english]] = true if info.tithi
      holiday_days += 1 if info.public_holiday?
      event_days += 1 unless info.events.empty?
      events += info.events.length
      info.events.each { |event| event_names[[event.nepali, event.english]] = true }
    end

    assert_equal SUMMARY["tithi_days"], tithi_days
    assert_equal SUMMARY["tithi_names"], tithi_names.length
    assert_equal SUMMARY["holidays"], holiday_days
    assert_equal SUMMARY["event_days"], event_days
    assert_equal SUMMARY["events"], events
    assert_equal SUMMARY["event_names"], event_names.length
  end

  def test_every_covered_day_matches_the_shared_json
    expected = {}
    Dir[File.join(PATRO_DIR, "*.json")].sort.each do |file|
      JSON.parse(File.read(file)).fetch("days").each { |key, value| expected[key] = value }
    end

    cursor = NepDate::Patro.coverage.start
    checked = 0
    while cursor <= NepDate::Patro.coverage.end
      source = expected[cursor.iso8601] || {}
      actual = NepDate::Patro.info(cursor)
      source_tithi = source["tithi"]
      if source_tithi
        assert_equal source_tithi["np"], actual.tithi_np, cursor.iso8601
        assert_equal source_tithi["en"], actual.tithi_en, cursor.iso8601
      else
        assert_nil actual.tithi, cursor.iso8601
      end
      assert_equal source["holiday"] == true, actual.public_holiday?, cursor.iso8601
      assert_equal (source["events"] || []).map { |event| event["np"] }, actual.events_np, cursor.iso8601
      assert_equal (source["events"] || []).map { |event| event["en"] }, actual.events_en, cursor.iso8601
      checked += 1
      cursor = cursor.succ
    end
    assert_equal SUMMARY["days"], checked
  end

  def test_the_calendar_info_value_type
    info = NepDate::Patro.info(NepDate::Date.parse("2081-01-01"))
    assert_equal info, NepDate::Date.parse("2081-01-01").calendar_info
    assert_equal info, NepDate::Patro.of(NepDate::Date.parse("2081-01-01"))
    assert_equal "Panchami", info.tithi.name(lang: :en)
    assert_equal "पञ्चमी", info.tithi.name(lang: :ne)
    assert_equal "New Year", info.events.first.name(lang: :en)
    assert_equal info.hash, NepDate::Patro.info(NepDate::Date.parse("2081-01-01")).hash
    assert_equal 3, info.to_h[:events].length
    assert_equal true, info.to_h[:public_holiday]
    assert_includes info.inspect, "Panchami"
  end

  private

  def info(text)
    NepDate::Patro.info(NepDate::Date.parse(text))
  end
end
