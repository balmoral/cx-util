require 'cx/util/csv/field'
require 'cx/util/stub'

# Example:
#
# class TickData < CX::CSV::Spec
#   field :symbol, :string
#   field :date,   :date,        format: '%Y-%m-%d'
#   field :time,   :time_of_day, format: '%d:%d:%d'
#   field :open,   :float
#   field :high,   :float
#   field :low,    :float
#   field :close,  :float
#   field :volume, :integer
# end
#
# supported types are:
#
#   :array
#   :hash
#   :date
#   :time
#   :time_of_day
#   :null
#   :float
#   :decimal
#   :boolean
#   :string
#   :symbol
#

module CX
  module CSV
    class Spec

      def self.field(name, type, opts = {})
        # puts "#{name}###{__method__}(#{name}, #{type}, #{opts})"
        sym = name.to_s.snake_case.to_sym
        field = CX::CSV::Field.new(sym: sym, name: name, type: type, **opts)
        # puts "#{name}###{__method__}:#{__LINE__} field '#{field}'"
        fields << field
      end
  
      def self.fields
        @fields ||= []
      end
  
      def self.field_names
        @fields.map(&:name) # do not cache
      end
  
      def self.field_index(field_name)
        fields.find_index(field_name.to_sym)
      end
  
      def self.field_count
        fields ? fields.size : 0
      end
  
      def self.csv_head
         field_names.to_csv
      end
  
      # may be overriden
      def self.header_rows
        1
      end
  
      # may be overriden
      def self.field_mappings
        nil
      end
  
      def self.reader
        CX::CSV::Reader
      end
  
      def self.read_args
        { fields: fields, header_rows: header_rows, field_mappings: field_mappings }
      end

      def self.rows_from_file(path)
        reader.read_file(path, **read_args)
      end

      def self.rows_from_string(str)
        reader.read_string(str, **read_args)
      end

      def self.rows_from_stream(io)
        reader.read_stream(io, **csv_read_args)
      end

      # RUBY MAGIC WARNING
      # Returns the stub class for the spec.
      # Default behaviour is to create an anonymous
      # class generated from this spec's fields.
      # This method can be overriden if a subclass
      # wants to specify a bespoke stub class.
      def self.stub_class(parent: nil)
        unless @stub_class
          @stub_class = Class.new(parent || CX::Stub)
          @stub_class.set_fields(field_names)
        end
        @stub_class
      end

      # Should return a hash which maps between
      # this spec's field symbols and its stub's
      # field/method names. The hash only needs to
      # map those fields which have different names.
      # Default here is to return nil (no map).
      # Subclasses may override.
      def self.stub_map
        nil
      end

      # Returns an array of stub 'attributes' (field/method names)
      # corresponding to each field in this csv spec.
      # If a field has a null type then the selector will be nil.
      # If a map is given, then it should map from each field sym
      # in this spec to a field (attribute) name in the stub.
      # If the map is given but does not contain a mapping for a field,
      # then the field's sym will be used as the stub attribute.
      def self.stub_attributes(map: nil)
        _map = map || self.stub_map
        fields.collect do |f|
          if f.null?
            nil
          else
            sym = f.sym
            _map ? (_map[sym] || sym) : sym
          end
        end
      end

      # Returns an array of stubs from the given rows.
      # If a stub class is not given it will be this spec's
      # default stub class, an anonymous class generated
      # orthogonally from this spec's fields. The optional
      # map (if given) should map from the field sym's
      # in this spec to the field name in the stub.
      def self.stubs_from_rows(rows, stub: nil, map: nil)
        puts "#{name}###{__method__}(rows.size = #{rows.size})"
        result = []
        stub_class = stub || self.stub_class
        attrs = stub_attributes(map: map)
        rows.each do |row|
          args = {}
          row.each_with_index do |v,i|
            attr = attrs[i]
            args[attr] = v if attr
          end
          result << stub_class.new(**args)
        end
        result
      end

      def self.stubs_from_file(path, stub: nil, map: nil)
        rows = rows_from_file(path)
        stubs_from_rows(rows, stub: stub, map: map)
      end

      def self.stubs_from_string(str, stub: nil, map: nil)
        rows = rows_from_string(str)
        stubs_from_rows(rows, stub: stub, map: map)
      end

      def self.stubs_from_stream(io, stub: nil, map: nil)
        rows = rows_from_stream(io)
        stubs_from_rows(rows, stub: stub, map: map)
      end

    end
  end
end