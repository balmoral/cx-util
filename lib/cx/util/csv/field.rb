require 'bigdecimal'
require 'cx/util/csv/constants'

module CX
  module CSV
    module Field
      class Base
        attr_reader :name
        attr_reader :quote
        attr_reader :read_accessor
        attr_reader :write_accessor


        def initialize(name: nil, quote: nil, read: nil, write: nil)
          @name = name || 'anon'
          @quote = quote
          @read_accessor = read ? read : name_to_accessor
          @write_accessor = write ? write : name_to_accessor('=')
        end

        def value_from_s(value)
          raise 'subclass responsibility'
        end

        def value_to_s(value)
          quote ? "#{quote}#{value}#{quote}" : value.to_s
        end

        def set_single_quoted
          @quote = CSV::SINGLE_QUOTE
        end

        def set_double_quoted
          @quote = CSV::DOUBLE_QUOTE
        end

        def is_hash_field
          false
        end

        def is_array_field
          false
        end

        def is_string_field
          false
        end

        def is_symbol_field
          false
        end

        def is_date_field
          false
        end

        def is_time_field
          false
        end

        def is_time_of_day_field
          false
        end

        def is_null_field
          false
        end

        def is_not_null_field
         true
        end

        def is_number_field
          false
        end

        def is_boolean_field
          false
        end

        # Returns converted value of next field in CVS.
        def read_csv(io)
          quoted = false
          str = ''
          io.each_char do |ch|
            case
              when (ch == CSV::COMMA && !quoted) || ch == CSV::LF || ch == CSV::CR || ch.nil?
                break
              when ch == quote
                quoted = !quoted
              else
                str << ch
            end
          end
          str.empty? ? nil : value_from_s(str)
        end

        private

        def name_to_accessor(postfix = nil)
          result = name.downcase.gsub(/ /, '_').gsub(/-/, '_')
          result << postfix if postfix
          result.to_sym
        end
      end

      # embedded subclasses

      class Array < Base
        attr_reader :value_field

        def initialize(name: nil, value: nil)
          super(name: name, quote: CSV::SINGLE_QUOTE)
          @value_field = value
        end

        def is_array_field
          true
        end

        def value_from_s(str)
          result = []
          _io = StringIO.new(str)
          until _io.eof?
            value = value_field.read_csv(_io)
            result << value if value
          end
          result
        end

        def value_to_s(ary)
          str = ''
          str << quote
          ary.each_with_index do |e, i|
            str << CSV::COMMA if i > 0
            str << value_field.value_to_s(e)
          end
          str << quote
          str
        end
      end # Array

      class Hash < Base
        attr_reader :value_field
        attr_reader :key_field

        def initialize(name: nil, key: nil, value: nil)
          super(name, CSV::SINGLE_QUOTE)
          @value_field = value
          @key_field = key
        end

        def is_hash_field
          true
        end

        def value_from_s(str)
          result = {}
          _io = StringIO.new(str)
          until _io.eof? do
            k = key_field.read_csv(_io)
            v = value_field.read_csv(_io) unless _io.eof?
            result[k] = v
          end
          result
        end

        def value_to_s(hash)
          str = ''
          str << quote
          i = 0
          hash.each_pair do |k, v|
            str << CSV::COMMA if i > 0
            str << key_field.value_to_s(k)
            str << CSV::COMMA
            str << value_field.value_to_s(v)
            i += 1
          end
          str << quote
          str
        end
      end # Hash

      class Date < Base
        attr_reader :format

        # Time.strftime formats - defaults to '%Y%m%d'
        def initialize(name: nil, format: '%Y%m%d', quote: nil)
          super(name: name, quote: quote)
          @format = format
        end

        def is_date_field
          true
        end

        def value_from_s(value)
          ::Date.parse(value, @format)
        end

        def value_to_s(value)
          value.strftime(format)
        end
      end

      class Time < Base
        attr_reader :format

        # Time.strftime for formats - defaults to '%Y%m%d%H%M%S'
        def initialize(name: nil, format: '%Y%m%d%H%M%S', quote: nil)
          super(name: name, quote: quote)
          @format = format
        end

        def is_time_field
          true
        end

        def value_from_s(value)
          ::DateTime.parse(value, @format).to_time
        end

        def value_to_s(value)
          value.strftime(format)
        end
      end

      class TimeOfDay < Base
        # NB - this treats time as the second in the day, not Ruby Time
        # Default format is '%d:%d:%d'
        # TODO: make a lot smarter ? H:M:S or h:m:s or h:m or HS ...
        def initialize(name: nil, format: '%d:%d:%d', quote: nil)
          super(name: name, quote: quote)
          @format = format
        end

        attr_reader :format

        def is_time_of_day_field
          true
        end

        # returns integer storing time (of day) as the number of seconds since midnight
        def value_from_s(value)
          a = value.scanf(@format)
          t = 0
          t += a[0] * 3600 if a.size > 0 # hours * seconds-per-hour
          t += a[1] * 60 if a.size > 1   # minutes * seconds-per-minute
          t += a[2] if a.size > 2        # seconds
          t.to_i
        end

        def value_to_s(value)
          t = value
          h = (t / 3600).truncate
          t -= h * 3600
          m = (t / 60).truncate
          s = t - m * 60
          sprintf(format, h, m, s)
        end
      end

      class Null < Base
        def is_null_field
          true
        end

        def value_from_s(value)
          nil
        end
      end

      class Float < Base
        def initialize(name: nil, quote: nil, precision: 6)
          @precision = precision
          super(name: name, quote: quote)
        end

        def precision
          @precision
        end

        def precision=(i)
          @precision = i
        end

        def is_number_field
          true
        end

        def value_from_s(value)
          value.to_f
        end

        def value_to_s(value)
          super value.round(precision)
        end
      end

      class Decimal < Base
        def initialize(name: nil, quote: nil, precision: 6)
          @precision = precision
          super(name: name, quote: quote)
        end

        def precision
          @precision
        end

        def precision=(i)
          @precision = i
        end

        def is_number_field
          true
        end

        def value_from_s(value)
          value.to_d
        end

        def value_to_s(value)
          super value.round(precision)
        end
      end

      class Integer < Base
        def initialize(name: nil, quote: nil)
          super(name: name, quote: quote)
        end

        def is_number_field
          true
        end

        def value_from_s(value)
          value.to_i
        end
      end

      class Boolean < Base
        def initialize(name: nil, quote: nil)
          super(name: name, quote: quote)
        end

        def is_boolean_field
          true
        end

        def value_to_s(value)
          value ? 'T' : 'F'
        end

        def value_from_s(value)
          value == 'T'
        end
      end

      class String < Base
        def initialize(name: nil, quote: nil)
          super(name: name, quote: quote)
        end

        def is_string_field
          true
        end

        def value_from_s(value)
          value.to_s
        end
      end

      class Symbol < Base
        def initialize(name: nil, quote: nil)
          super(name: name, quote: quote)
        end

        def is_symbol_field
          true
        end

        def value_from_s(value)
          value.to_sym
        end
      end

    end
  end
end