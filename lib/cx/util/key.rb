require 'cx/core/comparable'

module CX
  class Key
    include Comparable

    def self.[](*args)
      new(*args)
    end

    def initialize(*args)
      @values = args
      @hash = @values.hash
    end

    attr_reader :values, :hash

    def eql? (other)
      @hash == other.hash && @values == other.values
    end

    def == (other)
      eql?(other)
    end

    def <=> (other)
      @values <=> other.values
    end

    def [] (index)
      @values[index]
    end

    def to_s
      unless @_s
        @_s = '['
        @values.each.with_index do |v, i|
          @_s.concat(', ') unless i == 0
          @_s.concat(v.to_s)
        end
        @_s.concat(']')
      end
      @_s
    end

    def to_a
      @values
    end

  end
end

class Array
  def to_key
    CX::Key[*self]
  end
end