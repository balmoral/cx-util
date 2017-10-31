require 'cx/util/keyed'

module CX
  class TagValue
    include CX::Keyed

    attr_reader :tag, :value

    def initialize(tag, value)
      @tag, @value = tag, value
    end

    alias_method :key, :tag

    def to_s
      "#{tag}:#{value}"
    end

  end
end


