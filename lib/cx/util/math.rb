require 'cx/core'
# :TODO option for using BigDecimal
# require 'bigdecimal/util'
# require 'bigdecimal'

class Numeric
  # Returns string representation of number to given precision.
  # If no precision given, default is 2
  # TODO: rename to scale, precision should be overall length??
  def precision_s(p = 2)
    sprintf("%.#{p}f", self.to_d)
  end
end

class NilClass
  def to_d
    0.to_d
  end
end

module CX
  module Math
    #
    # Methods to handle basic math ops with possible nil values
    #
    def add(l, r)
      l && r ? l + r : nil
    end

    def subtract(l, r)
      l && r ? l - r : nil
    end

    def multiply(l, r)
      l && r ? l * r : nil
    end

    def divide(n, d)
      n && d && d != 0 ? n / d : nil
    end

    def power(n, e)
      n && e ? n ** e : nil
    end

    #
    # Percentage ops
    #
    def percent(n, d)
      r = divide(n, d)
      r ? r * 100 : nil
    end

    def delta_percent(n, d)
      r = divide(n - d, d)
      r ? r * 100 : nil
    end

    # Returns annual rate of return given an initial value, and final value and number of years (may be fractional)
    # NB - answer is expressed as percentage
    #
    # Reference Wikipedia:
    #
    # ERV == P (1 + T) ^  n
    # where
    # P == a hypothetical initial payment of $1,000
    # T == average annual total return
    # n == number of years
    # Solving for T gives
    # T == ( (ERV / P) ^  (1 / n) ) - 1
    #
    def annual_ror(initial_value, final_value, years)
      if years <= 0
        0
      elsif initial_value == 0
        # BigDecimal::INFINITY
        Float::INFINITY
      else
        100.to_d * if final_value < 0  # fudge if final value is less than zero
          (((initial_value.to_d - final_value.to_d) / initial_value.to_d) ** (1 / years.to_d)) * -1
        else
          ((final_value.to_d / initial_value.to_d) ** (1 / years.to_d)) - 1
        end
      end
    end
  end
end


