require 'bigdecimal'
require 'cx/core/constants'

# TODO: needs refactoring

module CX
  module Attribute

    module_function

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
    def klass(type)
      # wonderful world of Ruby - get a class from its name
      Module.const_get("CX::CSV::Attribute::#{type.to_s.camel_case}")
    end

    def new(sym: nil, name: nil, type: nil, **opts)
      klass(type).new(sym: sym, name: name, **opts)
    end

    class Base
      attr_reader :sym, :name, :quote


      def initialize(sym: nil, name: nil, quote: nil)
        @sym = sym
        @name = name || 'anon'
        @quote = quote
      end

      def value_from_s(value)
        raise 'subclass responsibility'
      end

      def value_to_s(value)
        quote ? "#{quote}#{value}#{quote}" : value.to_s
      end

      def set_single_quoted
        @quote = QUOTE_SINGLE
      end

      def set_double_quoted
        @quote = QUOTE_DOUBLE
      end

      def hash?
        false
      end

      def array?
        false
      end

      def string?
        false
      end

      def symbol?
        false
      end

      def date?
        false
      end

      def time?
        false
      end

      def time_of_day?
        false
      end

      def null?
        false
      end

      def number?
        false
      end

      def boolean?
        false
      end

      # Returns converted value of next attribute in CSV.
      def read_csv(io)
        quoted = false
        str = ''
        io.each_char do |ch|
          case
            when (ch == COMMA && !quoted) || ch == LF || ch == CR || ch.nil?
              break
            when ch == quote
              quoted = !quoted
            else
              str << ch
          end
        end
        str.empty? ? nil : value_from_s(str)
      end

    end

    # embedded subclasses

    class Array < Base
      attr_reader :value_attribute

      def initialize(sym: nil, name: nil, value: nil)
        super(sym: sym, name: name, quote: QUOTE_SINGLE)
        @value_attribute = value
      end

      def array?
        true
      end

      def value_from_s(str)
        result = []
        _io = StringIO.new(str)
        until _io.eof?
          value = value_attribute.read_csv(_io)
          result << value if value
        end
        result
      end

      def value_to_s(ary)
        str = ''
        str << quote
        ary.each_with_index do |e, i|
          str << COMMA if i > 0
          str << value_attribute.value_to_s(e)
        end
        str << quote
        str
      end
    end # Array

    class Hash < Base
      attr_reader :value_attribute
      attr_reader :key_attribute

      def initialize(sym: nil, name: nil, key: nil, value: nil)
        super(sym: sym, name: name, quote: QUOTE_SINGLE)
        @value_attribute = value
        @key_attribute = key
      end

      def hash?
        true
      end

      def value_from_s(str)
        result = {}
        _io = StringIO.new(str)
        until _io.eof? do
          k = key_attribute.read_csv(_io)
          v = value_attribute.read_csv(_io) unless _io.eof?
          result[k] = v
        end
        result
      end

      def value_to_s(hash)
        str = ''
        str << quote
        i = 0
        hash.each_pair do |k, v|
          str << COMMA if i > 0
          str << key_attribute.value_to_s(k)
          str << COMMA
          str << value_attribute.value_to_s(v)
          i += 1
        end
        str << quote
        str
      end
    end # Hash

    class Date < Base
      attr_reader :format

      # Time.strftime formats - defaults to '%Y%m%d'
      def initialize(sym: nil, name: nil, format: '%Y%m%d', quote: nil)
        super(sym: sym, name: name, quote: quote)
        @format = format
      end

      def date?
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
      def initialize(sym: nil, name: nil, format: '%Y%m%d%H%M%S', quote: nil)
        super(sym: sym, name: name, quote: quote)
        @format = format
      end

      def time?
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
      def initialize(sym: nil, name: nil, format: '%d:%d:%d', quote: nil)
        super(sym: sym, name: name, quote: quote)
        @format = format
      end

      attr_reader :format

      def time_of_day?
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
      def null?
        true
      end

      def value_from_s(value)
        nil
      end
    end

    class Float < Base
      def initialize(sym: nil, name: nil, quote: nil, precision: 6)
        @precision = precision
        super(sym: sym, name: name, quote: quote)
      end

      def precision
        @precision
      end

      def precision=(i)
        @precision = i
      end

      def number?
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
      def initialize(sym: nil, name: nil, quote: nil, precision: 6)
        @precision = precision
        super(sym: sym, name: name, quote: quote)
      end

      def precision
        @precision
      end

      def precision=(i)
        @precision = i
      end

      def number?
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
      def initialize(sym: nil, name: nil, quote: nil)
        super(sym: sym, name: name, quote: quote)
      end

      def number?
        true
      end

      def value_from_s(value)
        value.to_i
      end
    end

    class Boolean < Base
      def initialize(sym: nil, name: nil, quote: nil)
        super(sym: sym, name: name, quote: quote)
      end

      def boolean?
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
      def initialize(sym: nil, name: nil, quote: nil)
        super(sym: sym, name: name, quote: quote)
      end

      def string?
        true
      end

      def value_from_s(value)
        value.to_s
      end
    end

    class Symbol < Base
      def initialize(sym: nil, name: nil, quote: nil)
        super(sym: sym, name: name, quote: quote)
      end

      def symbol?
        true
      end

      def value_from_s(value)
        value.to_sym
      end
    end

    end
end