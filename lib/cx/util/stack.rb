require 'cx/util/debug'

# Standard array push/pop is too slow.
# Our own simple stack of a fixed size.
# Default size if 100.
module CX
  module Util
    class Stack < Array

      def initialize(_size = 100)
        super
        @ix = -1
      end

      def push(val)
        @ix += 1
        cx_error(__method__, "stack overflow: @ix #{@ix} >= size #{size}") unless @ix < size
        self[@ix] = val
      end

      def pop
        cx_error(__method__, "stack underflow: @ix #{@ix} < 0" ) if @ix < 0
        val = self[@ix]
        @ix -= 1
        val
      end

      def reset
        @ix = -1
      end

    end
  end
end