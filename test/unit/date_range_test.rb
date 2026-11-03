# frozen_string_literal: true

require_relative "../test_helper"

class DateRangeTest < Minitest::Test
  def setup
    @range = NepDate::DateRange.new(NepDate::Date.parse("2081-04-10"), NepDate::Date.parse("2081-04-20"))
  end

  def test_enumerable_and_length
    assert_equal 11, @range.length
    assert_equal 11, @range.size
    assert_equal 11, @range.to_a.length
    assert_equal 11, @range.count
    refute @range.empty?
    assert_equal %w[2081-04-10 2081-04-11], @range.first(2).map(&:iso8601)
    assert_equal "2081-04-20", @range.last.iso8601
    assert_equal %w[2081-04-10 2081-04-11 2081-04-12], @range.take(3).map(&:iso8601)
  end

  def test_membership_and_relations
    ten = NepDate::Date.parse("2081-04-10")
    twenty = NepDate::Date.parse("2081-04-20")
    assert @range.include?(ten)
    assert @range.include?(twenty)
    refute @range.include?(ten.add_days(-1))
    assert @range.contains?(ten)
    assert @range.contains_range?(NepDate::DateRange.new(ten.add_days(1), twenty.add_days(-1)))
    refute @range.contains_range?(NepDate::DateRange.new(ten.add_days(1), twenty.add_days(1)))
    assert @range.overlaps?(NepDate::DateRange.new(twenty, twenty.add_days(2)))
    refute @range.overlaps?(NepDate::DateRange.new(twenty.add_days(1), twenty.add_days(3)))
    assert @range.adjacent_to?(NepDate::DateRange.new(twenty.add_days(1), twenty.add_days(3)))
    assert NepDate::DateRange.new(twenty.add_days(1), twenty.add_days(3)).adjacent_to?(@range)
    refute @range.adjacent_to?(@range)
  end

  def test_set_operations
    overlapping = NepDate::DateRange.new(NepDate::Date.parse("2081-04-15"), NepDate::Date.parse("2081-04-25"))
    assert_equal "2081-04-15..2081-04-20", Outcome.range_text(@range.intersect(overlapping))
    assert_nil @range.intersect(NepDate::DateRange.new(NepDate::Date.parse("2081-05-01"), NepDate::Date.parse("2081-05-02")))
    assert_equal "2081-04-10..2081-04-25", Outcome.range_text(@range.union(overlapping))
    assert_equal ["2081-04-10..2081-04-14"], @range.except(overlapping).map { |range| Outcome.range_text(range) }
    inside = NepDate::DateRange.new(NepDate::Date.parse("2081-04-12"), NepDate::Date.parse("2081-04-18"))
    assert_equal ["2081-04-10..2081-04-11", "2081-04-19..2081-04-20"],
      @range.except(inside).map { |range| Outcome.range_text(range) }
    assert_empty @range.except(@range)
  end

  def test_split_and_days
    assert_equal 1, @range.split_by_month.length
    assert_equal @range, @range.split_by_month.first
    pieces = NepDate::DateRange.new(NepDate::Date.parse("2081-04-30"), NepDate::Date.parse("2081-06-02")).split_by_month
    assert_equal 3, pieces.length
    assert_equal "2081-04-30..2081-04-32", Outcome.range_text(pieces[0])
    assert_equal "2081-06-01..2081-06-02", Outcome.range_text(pieces[2])
    assert_equal [10, 13, 16, 19], @range.dates_with_interval(3).map(&:day)
    assert_equal [12, 19], @range.weekend_days(include_sunday: false).map(&:day)
    assert_equal [12, 13, 19, 20], @range.weekend_days.map(&:day)
    assert_equal [10, 11, 14, 15, 16, 17, 18],
      @range.working_days(exclude_sunday: true).map(&:day)
  end

  def test_value_equality_and_strings
    same = NepDate::DateRange.new(NepDate::Date.parse("2081-04-10"), NepDate::Date.parse("2081-04-20"))
    assert_equal @range, same
    assert_equal @range.hash, same.hash
    assert @range.eql?(same)
    assert_equal "2081/04/10 - 2081/04/20", @range.to_s
    assert_equal({start: @range.start, end: @range.end}, @range.to_h)
    assert_includes @range.inspect, "2081-04-10"
  end

  def test_errors
    assert_raises(TypeError) { @range.include?("2081-04-10") }
    assert_raises(TypeError) { @range.intersect("range") }
    assert_raises(NepDate::OutOfRangeError) { @range.dates_with_interval(0) }
    assert_raises(NepDate::OutOfRangeError) { NepDate::DateRange.from_day_count(@range.start, 0) }
    assert_raises(NepDate::OutOfRangeError) { NepDate::DateRange.from_day_count(NepDate::Date::MAX, 2) }
    assert_raises(TypeError) { NepDate::DateRange.new("2081-04-10", @range.end) }
  end
end
