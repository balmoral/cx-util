
module CX
  class Stats
    include Math

    attr_reader :sum, :min, :max, :count, :ave, :var, :dev
    attr_reader :dev_pos, :dev_neg
    attr_reader :var_pos, :var_neg
    attr_reader :n_pos, :n_neg

    # Will create an instance of stats from an enumerable.
    # If a select_block is given, this will be called
    # with each value and index - it should return a
    # value or nil, and only non-nil values will be processed.
    # A first_index and a final_index may also be given.
    # For non-array enumerables a counter will be used as
    # surrogate for array indexing.
    def initialize(enum, first_index: nil, final_index: nil, sample: false, &select_block)
      @sample = sample
      @count = 0
      @sum = 0.0
      @min = Float::MAX
      @max = Float::MIN
      @ave = @dev = @var = 0.0
      @dev_pos = @dev_neg = @var_pos = @var_neg = 0.0
      @n_pos = @n_neg = 0
      iterate(enum, first_index, final_index, :process, &select_block)
      @ave = @count == 0 ? 0 : @sum / @count
      calc_var(enum, first_index, final_index, &select_block)
      @dev = sqrt(@var)
      @dev_pos = sqrt(@var_pos)
      @dev_neg = sqrt(@var_neg)
    end

    def sample?
      @sample
    end

    def population?
      !@sample
    end

    alias sd dev
    alias sd_pos dev_pos
    alias sd_neg dev_neg
    alias sdev dev
    alias pos_count n_pos
    alias neg_count n_neg

    def annual_ror(years)
      Math::annual_ror(0, @sum, years)
    end

    private

    def iterate(enum, first_index, final_index, method, &select_block)
      no_first = first_index == nil || final_index < 0
      no_final = final_index == nil || final_index < 0
      no_select = select_block.nil?
      index = 0
      enum.each do |_val|
        if (no_first || index >= first_index) && (no_final || index <= final_index)
          val = no_select ? _val : yield(_val, index)
          send(method, val) if val
        end
        index += 1
      end
    end

    def process(val)
      @count += 1
      @sum += val
      if val < @min
        @min = val
      elsif val > @max
        @max = val
      end
    end

    def calc_var(enum, first_index, final_index, &select_block)
      if @count > 1
        iterate(enum, first_index, final_index, :process_var, &select_block)
        n = (@count - (@sample ? 1 : 0)).to_f
        @var /= n
        @var_pos /= n # @n_pos.to_f if @n_pos != 0
        @var_neg /= n # @n_neg.to_f if @n_neg != 0
      end
    end

    def process_var(val)
      delta = val - @ave
      delta2 = delta.squared
      @var += delta2
      if delta >= 0.0
        @var_pos += delta2
        @n_pos += 1
      end
      if delta <= 0.0
        @var_neg += delta2
        @n_neg += 1
      end
    end
  end
end

module Enumerable
  def stats(first_index: nil, final_index: nil, sample: false, &select_block)
    CX::Stats.new(self, first_index: first_index, final_index: final_index, sample: sample, &select_block)
  end
end