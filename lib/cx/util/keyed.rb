require 'cx/core/comparable'
require 'cx/util/debug'

# Keyed is a mixin to allow subclass instances
# to make themselves comparable by a key.
# Thus subclasses must define a 'key' method.
# Appropriate Comparable methods are then
# diverted to the key. Objects being compared
# with a keyed object must also implement
# a key method.
# eql? returns true if objects are same class and have same key
# ==   return true if objects have some key

module CX
  module Keyed
    include Comparable

    def key
      subclass_must_implement __method__
    end

    def hash
      key.hash
    end

    def eql?(other)
      self.class == other.class && key == other.key
    end

    def == (other)
      key == other.key
    end

    def <=> (other)
      lhs = key
      rhs = other.key
      if lhs == rhs
        0
      else
        lhs < rhs ? -1 : 1
      end
    end

  end
end