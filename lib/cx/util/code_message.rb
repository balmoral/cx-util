require 'cx/util/keyed'

module CX
  class CodeMessage
    include CX::Keyed

    attr_reader :code, :message

    def initialize(code, message)
      @code, @message = code, message
    end

    def key
      code
    end

    def to_s
      "#{code}:#{message}"
    end

  end
end


