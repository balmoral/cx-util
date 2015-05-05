require 'stringio'
require 'cx/util/csv/field'
require 'cx/util/csv/reader'

module CX
  module CSV
    class Table
      include Enumerable

      def self.reader
        CX::CSV::Reader
      end

      def self.name
        subclass_must_implement __method__
      end

      def self.fields
        subclass_must_implement __method__
      end

      def self.csv_header_row_count
        1
      end

      def self.csv_field_mappings
        nil
      end

      def initialize(name = self.class.name, fields = self.class.fields, rows = nil)
        @name = name
        @fields = fields
        @rows = rows || []
      end

      attr_reader :name, :fields, :rows

      def csv_header_row_count
        self.class.csv_header_row_count
      end

      def csv_field_mappings
        self.class.csv_field_mappings
      end

      def reader
        self.class.reader
      end

      def read_csv_file(path, _file_name, header_row_count = csv_header_row_count, field_mappings = csv_field_mappings)
        file_name = _file_name || name
        csv_rows = reader.read_file(path, file_name, fields, header_row_count, field_mappings)
        rows.concat(csv_rows)
      end

      def read_csv_string(str, header_row_count = csv_header_row_count, field_mappings = csv_field_mappings)
        csv_rows = reader.read_string(str, fields, header_row_count, field_mappings)
        rows.concat(csv_rows)
      end

      def read_csv_stream(io, header_row_count = csv_header_row_count, field_mappings = csv_field_mappings)
        csv_rows = reader.read_stream(io, fields, header_row_count, field_mappings)
        rows.concat(csv_rows)
      end

      def to_csv_file(path, file_name, header_row_count = csv_header_row_count, field_mappings = csv_field_mappings)
        unfinished_code __method__
      end

      def each
        rows.each { |e| yield e }
      end

      def [](index)
        @rows[index]
      end

      def size
        row_count
      end

      def length
        row_count
      end

      def row_count
        @rows.length
      end

      def hash_keyed_by_column(column_index)
        hash = Hash.new
        @rows.each do |row|
          hash[row[column_index]] = row
        end
        hash
      end

      def column_to_set(column_index)
        set = Set.new
        @rows.each { |row| set << row[column_index] }
        set
      end

      def row(index)
        @rows[index]
      end

      def column(col_index)
        @rows.collect { |row| row[col_index] }
      end

      def column_count
        fields ? fields.size : 0
      end

      def empty?
        row_count == 0
      end

    end
  end
end