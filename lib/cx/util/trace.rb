require 'singleton'

# TODO: find usages
module CX
  class Trace
    include Singleton

    def initialize
      @list = {}
    end

    def for?(klass)
      @list.has_key?(klass.name)
    end

    def << (klass)
      @list[klass.name] = klass
    end
  end
end