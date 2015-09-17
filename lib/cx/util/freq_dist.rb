require 'cx/util/stats'

# A frequency distribution based on standard deviations.
# Intervals contains the values from which fd is constructed.
# Frequencies are expressed as f / n where
#   f is the frequency (count) of given values in an interval and
#   n is the total number (count) of given values
#
module CX
class FreqDist

  attr_reader :stats, :sd_factors, :intervals, :freqs

  def initialize(ary, offset = 0, &select_block)
    assert(ary)
    @stats = CX::Stats.new(ary, offset, &select_block)
    @sd_factors = self.class.sd_factors
    @intervals = Array.new(sd_factors.size) { |i| @stats.ave + @stats.sd * @sd_factors[i] }
    @freqs = Array.new(@intervals.size, 0)
    no_select = select_block.nil?
    iterate(ary, offset) do |v,i|
      process(v) if no_select || yield(v, i)
    end
    n = ary.size.to_f
    @freqs.size.times do |i|
      @freqs[i] = @freqs[i].to_f / n
    end
  end

  private

  def iterate(ary, offset)
    (0 + offset).max(0).upto((ary.size + offset - 1).min(ary.size - 1)) do |i|
      yield(ary[i], i)
    end
  end

  def process(val)
    @intervals.size.times do |i|
      if val < @intervals[i]
        @freqs[i] += 1
        break
      end
    end
  end

  def self.sd_factors
    @sd_factors ||= [-5.0,-4.0,-3.0,-2.0,-1.0,-0.5,0.0,0.5,1.0,2.0,3.0,4.0,5.0,99.9]
  end

end
end

class Array
  def freq_dist; CX::FreqDist.new(self) end
end