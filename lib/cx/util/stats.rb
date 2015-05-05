
module CX
  class Stats
    include Math

    attr_reader :sum, :min, :max, :count, :ave, :var, :sd

    # Will create an instance of stats from an enumerable.
    # An starting offset can be given, so that stats are only
    # accumulated once the offset index has been reach.
    # Uses Enumerable#each_with_index to enumerate.
    # If a select_block is given, this will be called
    # # with each value and index, and only values
    # for which this returns true will be
    # considered in the stats.
    #
    def initialize(enum, offset: 0, sample: true, &select_block)
      @sample = sample
      @count = 0
      @sum = 0.to_d
      @min = Float::MAX.to_d
      @max = Float::MIN.to_d
      @ave = @sd = @var = nil
      no_select = select_block.nil?
      iterate(enum, offset) do |v,i|
        process(v) if no_select || yield(v, i)
      end
      @ave = @count == 0 ? 0 : @sum / @count
      @var = @count == 0 ? 0 : calc_var(enum, offset, &select_block)
      @sd = sqrt @var
    end

    def sample?
      @sample
    end

    def population?
      !@sample
    end

    def dev
      @sd
    end

    def annual_ror(years)
      Math::annual_ror(0, @sum, years)
    end

    private

    def iterate(enum, offset)
      enum.each_with_index do |e, i|
        yield e, i unless i < offset
      end
    end

    def process(_val)
      val = _val.to_d
      @count += 1
      @sum += val
      @min = val if val < @min
      @max = val if val > @max
    end

    def calc_var(enum, offset, &select_block)
      if @count < 2
        0
      else
        v = 0.to_d
        nil_block = select_block.nil?
        iterate(enum, offset) do |e,i|
          v += (e - @ave).squared if nil_block || yield(e, i)
        end
        v / (@count - (@sample ? 1 : 0)).to_f
      end
    end

  end
end

module Enumerable
  def stats
    CX::Stats.new(self)
  end
end