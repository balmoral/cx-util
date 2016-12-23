require 'cx/util/keyed'

module CX
  class CodeMessage
    include CX::Keyed

    def initialize(code, message)
      @code, @message = code, message
    end

    def message
      @message
    end

    def key
      @code
    end

    def to_s
      "#{code}:#{message}"
    end

    def label
      to_s
    end

  end
end


