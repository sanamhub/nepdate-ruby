# frozen_string_literal: true

require_relative "../test_helper"

# csharp-tests/catalog.tsv: every test case of C# NepDate's suite tagged with the phase that covers
# it. The catalog is an inventory, not a set of expected outputs; this test keeps its shape and
# phase counts from drifting, while the behaviour is asserted by the other vector files.
class CatalogTest < Minitest::Test
  PHASES = ["1", "2", "3", "4", "D-14", "n/a"].freeze
  EXPECTED = {"1" => 113, "2" => 180, "3" => 148, "4" => 40, "D-14" => 17, "n/a" => 44}.freeze

  def test_every_row_is_well_formed_and_has_a_known_phase
    rows = Vectors.load("csharp-tests/catalog.tsv")
    assert_equal 542, rows.length

    seen = {}
    phases = Hash.new(0)
    rows.each do |row|
      id = row["id"]
      refute_empty id
      refute seen.key?(id), "duplicate catalog row: #{id}"
      seen[id] = true
      refute_empty row["file"], id
      refute_empty row["method"], id
      assert row.key?("asserts"), id
      assert_includes PHASES, row["phase"], "unknown phase in #{id}"
      phases[row["phase"]] += 1
    end

    assert_equal EXPECTED, phases
  end

  def test_the_catalog_names_the_files_of_the_csharp_suite
    files = Vectors.load("csharp-tests/catalog.tsv").map { |row| row["file"] }.uniq
    assert_operator files.length, :>, 10
    files.each { |file| assert file.end_with?(".cs"), file }
  end
end
