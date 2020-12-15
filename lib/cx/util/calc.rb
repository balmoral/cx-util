require 'cx/util/stats'

module CX
  module Calc
    def sum(enum)
      y = block_given?
      enum.inject(0) {|r,e| r + (y ? yield(e) : e) }
    end
    
    def ave(enum)
      c = count(enum)
      c == 0 ? nil : sum(enum).to_f / c.to_f
    end

    def mid(enum)
      _min = min(enum)
      _min ? (_min + max(enum)) / 2 : nil
    end

    def min(enum)
      y = block_given?
      r = enum.inject(Float::MAX){|r,e| r.min (y ? yield(e) : e) }
      r == Float::MAX ? nil : r
    end

    def max(enum)
      y = block_given?
      r = enum.inject(Float::MIN){|r,e| r.max (y ? yield(e) : e) }
      r == Float::MIN ? nil : r
    end

    def count(enum)
      enum.size
    end

    def stats(enum)
      y = block_given?
      Stats.new(enum.collect {|e| (y ? yield(e) : e) })
    end

    def dev(enum)
      stats(enum).dev
    end

    def var(enum)
      stats(enum).var
    end
  end
end
