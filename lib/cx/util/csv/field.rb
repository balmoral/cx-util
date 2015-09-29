require 'bigdecimal'
require 'cx/core/constants'
require 'cx/core/date'
require 'cx/core/time'
require 'cx/core/time_of_day'

# TODO: needs refactoring

module CX
  module CSV
    module Field

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
      #   :integer
      #   :decimal
      #   :boolean
      #   :string
      #   :symbol
      #
      def klass(type)
        # wonderful world of Ruby - get a class from its name
        Module.const_get("CX::CSV::Field::#{type.to_s.camel_case}")
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

        # Returns converted value of next field in CSV.
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
        attr_reader :value_field

        def initialize(sym: nil, name: nil, value: nil)
          super(sym: sym, name: name, quote: QUOTE_SINGLE)
          @value_field = value
        end

        def array?
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
            str << COMMA if i > 0
            str << value_field.value_to_s(e)
          end
          str << quote
          str
        end
      end # Array

      class Hash < Base
        attr_reader :value_field
        attr_reader :key_field

        def initialize(sym: nil, name: nil, key: nil, value: nil)
          super(sym: sym, name: name, quote: QUOTE_SINGLE)
          @value_field = value
          @key_field = key
        end

        def hash?
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
            str << COMMA if i > 0
            str << key_field.value_to_s(k)
            str << COMMA
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

      class Yyyymmdd < Base
        attr_reader :format

        # Time.strftime formats - defaults to '%Y%m%d'
        def initialize(sym: nil, name: nil, format: '%Y%m%d', quote: nil)
          super(sym: sym, name: name, quote: quote)
          @format = format
          @value_proc = case @format

            when '%Y%m%d'
              ->(v) { v }
            when '%d%m%Y'
              ->(v) { "#{v[4,4]}#{v[2,2]}#{v[0,2]}" }
            when '%m%d%Y'
              ->(v) { "#{v[4,4]}#{v[0,2]}#{v[2,2]}" }

            when '%y%m%d'
              ->(v) { "#{ypad(v[0,2])}#{v[2,2]}#{v[0,2]}" }
            when '%d%m%y'
              ->(v) { "#{ypad(v[4,2])}#{v[2,2]}#{v[0,2]}" }
            when '%m%d%y'
              ->(v) { "#{ypad(v[4,2])}#{v[0,2]}#{v[2,2]}" }

            when '%Y-%m-%d', '%y-%m-%d'
              ->(v) { ymd(v, '-') }
            when '%Y/%m/%d', '%y/%m/%d'
              ->(v) { ymd(v, '/') }
            when '%Y:%m:%d', '%y:%m:%d'
              ->(v) { ymd(v, ':') }

            when '%d-%m-%Y', '%d-%m-%y'
              ->(v) { dmy(v, '-') }
            when '%d/%m/%Y', '%d/%m/%Y'
              ->(v) { dmy(v, '/') }
            when '%d:%m:%Y', '%d:%m:%y'
              ->(v) { dmy(v, ':') }

            when '%m-%d-%Y', '%m-%d-%y'
              ->(v) { mdy(v, '-') }
            when '%m/%d/%Y', '%m/%d/%Y'
              ->(v) { mdy(v, '/') }
            when '%m:%d:%Y', '%m:%d:%y'
              ->(v) { mdy(v, ':') }

            else
             raise MissingCase, "unsupported yyyymmdd format '#{@format}'"
          end
        end

        def value_from_s(value)
          @value_proc.call(value)
        end

        def value_to_s(value)
          value
        end

        private

        def ymd(ymd, sep)
          y, m, d = ymd.split(sep)
          "#{ypad(y)}#{pad2(m)}#{pad2(d)}"
        end

        def mdy(mdy, sep)
          m, d, y = mdy.split(sep)
          "#{ypad(y)}#{pad2(m)}#{pad2(d)}"
        end

        def dmy(dmy, sep)
          d, m, y = dmy.split(sep)
          "#{ypad(y)}#{pad2(m)}#{pad2(d)}"
        end

        def ypad(s)
          case s.size
            when 1 then "200#{s}"
            when 2 then s < '50' ? "19#{s}" : "20#{s}"
            when 4 then s
            else
              raise MissingCase, "unexpected value for year '#{s}'"
          end
        end

        def pad2(s)
          s.size == 2 ? s : "0#{s}"
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

      class Hhmmss < Base
        # NB - this treats time as the second in the day, not Ruby Time
        # Supported input string formats are:
        #   '%H%M%S'
        #   '%H:%M:%S', %H-%M-%S', '%H/%M/%S'
        #   '%h:%m:%s', '%h-%m-%s', '%h/%m/%s'
        def initialize(sym: nil, name: nil, format: '%H:%M:%S', quote: nil)
          super(sym: sym, name: name, quote: quote)
          @format = format
          @value_proc = case @format

            when '%H%M%S'
              ->(v) { v }
            when '%H:%M:%S'
              ->(v) { v.gsub(/:/, '') }
            when '%H-%M-%S'
              ->(v) { v.gsub(/-/, '') }
            when '%H/%M/%S'
              ->(v) { v.gsub(/\//, '') }

            when '%h:%m:%s'
              ->(v) { hhmmss(v, ':') }
            when '%h-%m-%s'
              ->(v) { hhmmss(v, '-') }
            when '%h/%m/%s'
              ->(v) { hhmmss(v, '/') }

            else
              raise MissingCase, "unsupported hhmmss format '#{format}'"
          end
        end

        attr_reader :format

        # returns integer storing time (of day) as the number of seconds since midnight
        def value_from_s(value)
          @value_proc.call(value)
        end

        def value_to_s(value)
          value
        end

        private

        def hhmmss(hms, sep)
          h, m, s = hms.split(sep)
          "#{pad(h)}#{pad(m)}#{pad(s)}"
        end

        def pad(s)
          s.size == 2 ? s : "0#{s}"
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
end