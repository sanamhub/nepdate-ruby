# frozen_string_literal: true

# Loads the shared vector files under shared/spec/vectors/. Every file is tab-separated (the CSV
# file is passed with a comma), starts with an optional # comment block and then a header row.
module Vectors
  ROOT = File.expand_path("../../shared/spec/vectors", __dir__)

  module_function

  def path(relative)
    File.join(ROOT, relative)
  end

  def load(relative, delimiter: "\t")
    lines = File.readlines(path(relative), chomp: true, encoding: "UTF-8")
    header = nil
    rows = []
    lines.each do |line|
      next if line.empty? || line.start_with?("#")

      columns = line.split(delimiter, -1)
      if header.nil?
        header = columns
        next
      end
      if columns.length != header.length
        raise "vector row has #{columns.length} columns, header has #{header.length}: #{relative}: #{line}"
      end
      rows << header.zip(columns).to_h
    end
    rows
  end

  def list(value)
    return [] if value == "none" || value.empty?

    value.split(";")
  end

  def range(value)
    value.split("..", 2)
  end

  def error?(value)
    value == "ERR" || value.start_with?("ERR:")
  end

  def error_kind(value)
    value.start_with?("ERR:") ? value.delete_prefix("ERR:") : nil
  end

  def count(relative, delimiter: "\t")
    load(relative, delimiter: delimiter).length
  end
end
