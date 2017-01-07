# We approximate java enum here with a macro class enum method
# which takes the enum name (id) and enum value (any object).
#
# To define an enum class, for example, use:
#
#   class Errors < CX::Enum
#     = :IO, "io error"
#     ...
#   end
#
# If no value is given for the enum then it will
# default to an integer equal in value to the
# number of enums already defined/declared.
#
# Additionally, the enum name/value pairs
# can be added as class constants using the
# class method ##constantize. This should be
# done once after all enum values have been
# declared. NB enum names must start with
# an upper case letter if they are to made
# constant - otherwise will generate a compile
# error.
#
# To get an enum value, for example, use:
#
#   Errors[:IO]
#
# which will return the value of the enum
# with name :IO.
#
# If ##constantize has been called, then
# you can also use:
#
#    Errors::IO
#
# which will return the value of the enum
# with name :IO.
#
# To get the enum instance for a given name use
#
#    Errors.with_name(name)
#
# To get the enum instance for a given value use
#
#    Errors.with_value(value)
#
# To determine concisely whether an enum is defined use
#
#     Errors.defined?(name)
#
module CX
  class Enum

    def self.enums
      @enums ||= {}
    end

    # Must be called in subclass before its enums are declared.
    def self.constantize_ordinal
      @constantizer = :ordinal
    end
    def self.constantize_name
      @constantizer = :name
    end
    def self.constantize_value
      @constantizer = :value
    end
    def self.constantize_enum
      @constantizer = :enum
    end

    def self.constantizer
      @constantizer
    end

    def self.constantize?
      !!@constantizer
    end

    def self.enum(name, value: nil, ordinal: nil)
      if enums[name]
        fail "#{__FILE__}[#{__LINE__}:#{self.class.name}##enum(#{name}, #{value}) : enum already defined"
      end
      ordinal ||= enums.empty? ? 0 : enums.values.last.ordinal + 1
      enums[name] = enum = new(name, value, ordinal)
      create_constant(enum) if constantize?
    end

    # Returns instance of Enum with given name
    # or nil if none found.
    def self.[](name)
      enums[name]
    end

    # Alias for #[]
    def self.with_name(name)
      self[name]
    end

    # Returns (first) instance of Enum which
    # has the given value, or nil if none found.
    def self.with_value(value)
      enums.each_value do |enum|
        return enum if enum.value == value
      end
      nil
    end

    # Returns (first) instance of Enum which
    # has the given ordinal value, or nil
    # if none found.
    def self.with_ordinal(ordinal)
      enums.each_value do |enum|
        return enum if enum.ordinal == ordinal
      end
      nil
    end

    # Returns whether enum with given name has been
    # defined/declared.
    def self.defined?(name)
      !!with_name(name)
    end

    # alias for defined?
    def self.declared?(name)
      defined?(name)
    end

    def self.create_constant(enum)
      const_value = case @constantizer
        when :ordinal
          enum.ordinal
        when :name
          enum.name.to_s
        when :value
          enum.value || enum.ordinal
        when :enum, nil
          enum
      end
      const_set(enum.name.to_s, const_value) if const_value
    end

    attr_reader :name, :value, :ordinal

    def initialize(name, value, ordinal)
      @name = name
      @value = value || name.to_s
      @ordinal = ordinal
    end

    def ==(other)
      other.class == self.class && other.name == self.name
    end

    # This follows java convention where enum toStrong()
    # defaults to reurning the name (name of the enum).
    def to_s
      name.to_s
    end
  end
end
