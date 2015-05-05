require 'stringio'
require 'cx/util/csv/constants'
require 'cx/util/csv/field'
require 'cx/util/debug'

module CX
  module CSV
    module Reader

      # Opens and processes file. If a block is given then
      # fields, header_rows and field_mappings are ignored
      # and the file io stream is passed to the given block.
      # If no block is given then file is automatically processed
      # returning an array of arrays, the latter being the rows of
      # the csv converted according to field and other parameters.
      def self.read_file(path, file_name, fields = nil, header_rows = 0, field_mappings = nil)
        Kernel.open((path / file_name).to_s, 'r') do |io|
          if block_given?
            yield io
          else
            read_stream(io, fields, header_rows, field_mappings)
          end
        end
      end

      def self.read_string(str, fields = nil, header_rows = 0, field_mappings = nil)
        read_stream(StringIO.new(str), fields, header_rows, field_mappings)
      end

      def self.read_stream(io, fields = nil, header_rows = 0, _field_mappings = nil)
        rows = []
        if fields
          field_mappings = _field_mappings || (0...fields.size).to_a
          num_fields = field_mappings.count{ |e| e >= 0 }
          if num_fields > 0
            soak_header_rows(io, header_rows)
            loop do
              break if io.eof?
              rows << read_line_to_a(io, fields, field_mappings, num_fields)
              # printf("%s read row[%d]\n", name, rows.size) if true && rows.size.multiple?(100)
            end
          end
        else
          loop do
            break if io.eof?
            rows << read_line_to_a(io, fields, field_mappings, num_fields)
            # printf("%s read row[%d]\n", name, rows.size) if true && rows.size.multiple?(100)
          end
        end
        rows
      end

      # Read next line from csv and return array of values.
      # If fields are given then values in csv are read accordingly and mapped.
      # If fields given, expect corresponding number and types of fields in line.
      # If no fields are given line is read and split into string values (number may vary).
      def self.read_line_to_a(io, fields, field_mappings, num_fields)
        if fields
          row = Array.new(num_fields)
          field_mappings.each_with_index do |mapped_field_index, source_field_index|
            break if io.eof?
            # must read value to soak up io, even if field not mapped
            value = read_field(io, fields[source_field_index])
            unless mapped_field_index < num_fields
              cx_error __method__,  'mapped_field_index >= num_fields'
            end
            row[mapped_field_index] = value unless mapped_field_index < 0
          end
          soak_eol(io)
        else
          line = String.new
          soak_line(io, line)
          row = line.split(COMMA)
        end
        row
      end

      # Read next line from csv passing each value
      # (and associated field and field index) to given block.
      # e.g. csv_reader.read_line(io, fields) { |value, field, field_index| ... }
      # remainder of line will be soaked up if asked (default is true)
      # no error raised if file ends early - field values won't be passed
      def self.read_line(io, fields, do_soak_eol = true)
        fields.each_with_index do |f, i|
          break if io.eof?
          yield read_field(io, f), f, i
        end
        soak_eol(io) if do_soak_eol
      end

      # Returns converted value of next field in CVS
      def self.read_field(line_io, field)
        field.read_csv(line_io)
      end

      private # instance methods


      # Soak up any line terminals
      def self.soak_eol(io)
        loop do
          ch = io.getc
          break if ch.nil?
          #pre 1.9 may return byte - we can't handle that
          raise DataError, 'expected character as String' unless ch.is_a? String
          unless ch == LF || ch == CR
            io.ungetc(ch)
            break
          end
        end
      end

      # Soak up a line. If out string is given
      # add each non eol char to it, otherwise
      # ignore each char.
      def self.soak_line(io, out = nil)
        loop do
          ch = io.getc
          return if ch.nil?
          break if ch == CSV::LF || ch == CSV::CR
          out << ch if out
        end
        soak_eol(io)
      end

      def self.soak_header_rows(io, header_rows)
        row_count = 0
        while row_count < header_rows
          soak_line(io)
          row_count += 1
        end
      end
    end
  end
end
