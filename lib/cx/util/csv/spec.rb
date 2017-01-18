require 'cx/util/csv/field'
require 'cx/util/csv/reader'
require 'cx/util/model'

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
# or for dates and time of day as  strings:
#
# class TickData < CX::CSV::Spec
#   field :symbol, :string
#   field :date,   :yyyymmdd,  format: '%Y-%m-%d'
#   field :time,   :hhmmss,    format: '%H:%M:%S'
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
#   :yyyymmdd
#   :hhmmss
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

      # may be overridden
      def self.params
        {}
      end

      def self.header_rows
        params[:header_rows] || 1
      end
  
      def self.field_mappings
        params[:field_mappings]
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
        reader.read_stream(io)
      end

      # RUBY MAGIC WARNING
      # Returns the model class for the spec.
      # Default behaviour is to create an anonymous
      # class generated from this spec's fields.
      # This method can be overriden if a subclass
      # wants to specify a bespoke model class.
      def self.model_class(parent: nil)
        unless @model_class
          @model_class = Class.new(parent || CX::Model)
          @model_class.attrs = field_names
        end
        @model_class
      end

      # Should return a hash which maps between
      # this spec's field symbols and its model's
      # field/method names. The hash only needs to
      # map those fields which have different names.
      # Default here is to return nil (no map).
      # Subclasses may override.
      def self.model_map
        nil
      end

      # Returns an array of model 'attributes' (field/method names)
      # corresponding to each field in this csv spec.
      # If a field has a null type then the selector will be nil.
      # If a map is given, then it should map from each field sym
      # in this spec to a field (attribute) name in the model.
      # If the map is given but does not contain a mapping for a field,
      # then the field's sym will be used as the model attribute.
      def self.model_attributes(map: nil)
        _map = map || self.model_map
        fields.collect do |f|
          if f.null?
            nil
          else
            sym = f.sym
            _map ? (_map[sym] || sym) : sym
          end
        end
      end

      # Returns an array of models from the given rows.
      # If a model class is not given it will be this spec's
      # default model class, an anonymous class generated
      # orthogonally from this spec's fields. The optional
      # map (if given) should map from the field sym's
      # in this spec to the field name in the model.
      def self.models_from_rows(rows, model_class: nil, map: nil)
        # puts "#{name}###{__method__}(rows.size = #{rows.size})"
        result = []
        model_class ||= self.model_class
        attrs = model_attributes(map: map)
        rows.each do |row|
          args = {}
          row.each_with_index do |v,i|
            attr = attrs[i]
            args[attr] = v if attr
          end
          result << model_class.new(**args)
        end
        result
      end

      def self.models_from_file(path, model_class: nil, map: nil)
        rows = rows_from_file(path)
        models_from_rows(rows, model_class: model_class, map: map)
      end

      def self.models_from_string(str, model_class: nil, map: nil)
        rows = rows_from_string(str)
        models_from_rows(rows, model_class: model_class, map: map)
      end

      def self.models_from_stream(io, model_class: nil, map: nil)
        rows = rows_from_stream(io)
        models_from_rows(rows, model_class: model_class, map: map)
      end

    end
  end
end