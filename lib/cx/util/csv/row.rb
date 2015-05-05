require 'cx/core/file_path'
require 'cx/util/csv/reader'
require 'cx/util/csv/field'
require 'cx/util/csv/constants'

module CX
  module CSV
    module Row

      def to_csv_s
        result = String.new
        csv_fields.each_with_index do |field, i|
          result << CSV::COMMA if i > 0
          value = send(field.read_accessor) # send method to me, if missing, subclass must implement
          result << field.value_to_s(value)
        end
        result
      end

      def from_csv_line(io)
        CSV::Reader.read_line(io, csv_fields) do |value, field, _field_index|
          if field.write_accessor == :step=
            value
          end
          send(field.write_accessor, value) # send method to me, if missing, subclass must implement
        end
        self
      end

      # Returns an array of CSV::Field's.
      # Default behaviour is to call class method #csv_fields.
      def csv_fields
        self.class.csv_fields
      end

      # Row class methods - only need to include this mixin
      # and class methods will automatically be extended.
      # See "Eloquent Ruby" p255 for explanation of
      # module 'class' methods.
      module ClassMethods

        def csv_fields
          subclass_must_implement __method__
        end

        def keyword_initialize?
          false
        end

        def hash_from_csv_line(io)
          hash = {}
          CSV::Reader.read_line(io, csv_fields) do |value, field, field_index|
            hash[field.read_accessor] = value
          end
          hash
        end

        # Returns instance from csv line.
        # If the class wants instances to be initialized
        # via keyword hash then the field read accessors
        # will be used as the argument keys. Otherwise
        # an instance will be created without arguments
        # and instance write accessors used to set values.
        def from_csv_line(io)
          if keyword_initialize?
            new **hash_from_csv_line(io)
          else
            new.from_csv_line(io)
          end
        end

        # Returns array of rows from csv lines.
        def from_csv_lines(io)
          result = []
          until io.eof? do
            result << from_csv_line(io)
            CSV::Reader.soak_eol(io)
          end
          result
        end

        # Returns array of rows from csv file.
        def from_csv_file(path, file_name)
          puts "reading #{path}/#{file_name}"
          result = nil
          reader = CSV::Reader
          reader.read_file(path, file_name) do | io |
            reader.soak_header_rows(io, 1)
            result = from_csv_lines(io)
          end
          result
        end

        # Writes rows to file with given name and path
        # create directories and file as necessary.
        # Overwrites existing file.
        def to_csv_file(path, file_name, rows)
          puts "writing #{path}/#{file_name}"
          path.assure_existence
          Kernel.open((path / file_name).to_s, 'w+') do |io|
            io.puts csv_header
            rows.each do |t|
              io.puts t.to_csv_s
            end
          end
        end

        # Returns str containing csv lines from given rows
        def to_csv_str(rows)
          rows.inject('') {|s,t| s << t << CSV::LF }
        end

        # Returns string containing csv header line.
        def csv_header
          result = String.new
          csv_fields.each_with_index do |field, i|
            result << CSV::COMMA if i > 0
            result << field.name
          end
          result
        end
      end

      # when I'm included, extend my host class with my ClassMethods !
      def self.included(host_class)
        host_class.extend(ClassMethods)
        super
      end
    end

  end
end
