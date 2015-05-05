require 'cx/util/debug'

# Random encapsulates random number generation.
# Integer and boolean focus.
# Lots of useful collection stuff.
# Uses Ruby kernel rand method.
# Synchronizes calls to rand for thread safety.
# Extends Array to invoke random collection methods.

module CX
  class Random

    # A convenience instance of Random.
    # You can create others as required.
    def self.instance
      @instance ||= new Time.now
    end

    # A seed may be provided to allow determined sequence of random numbers.
    # If no seed is given the sequence of random numbers will be undetermined.
    def initialize(seed = nil)
      @generator = seed ? Random.new(seed) : Random.new
    end

    attr_reader :generator

    # Returns a random integer greater than or equal to 0 and less than limit.
    def int(limit)
      assert limit.is_a?(Integer), 'expected integer argument'
      sync { i = @generator.rand limit }
      assert i.is_a?(Integer), 'expected integer from rand'
      i
    end

    # Returns the given array after shuffling its contents in-line
    # Code from Masters 2006, p19, adapted to constrain indexes
    def shuffle!(ary, arg_first_index = nil, arg_final_index = nil)
      first_index = arg_first_index ? arg_first_index : 0
      final_index = arg_final_index ? arg_final_index : ary.size - 1
      k1 = final_index
      while k1 >= first_index do
        k2 = int(k1 + 1)
        unless k1 == k2
          ary[k1], ary[k2] = ary[k2], ary[k1]
        end
        k1 -= 1
      end
      ary
    end

    # Returns a new array with shuffled contents of given array.
    def shuffle(ary)
      shuffle! ary.copy
    end

    # Returns randomly chosen element of collection.
    def choice(collection)
      collection[ int collection.size ]
    end

    alias lucky_dip choice

    # Returns randomly chosen element of collection or nil
    def choice_or_nil(collection)
      collection[ int collection.size + 1 ]
    end

    # Returns one or the other chosen randomly.
    def either(one, other)
      truth? ? one : other
    end

    # Returns true or false chosen randomly.
    def truth?
      int(2) == 0
    end

    # Returns true with probability of 1/n, false with probability (n-1)/n.
    def one_in?(n)
      n <= 1 ? true : (int(n) == 0)
    end

    # Returns true with probability of chance/n, false with probability (n-chance)/n
    def chance_in?(chance, n)
      int(n) < chance
    end

    # Returns a random integer in the inclusive interval begin min and max.
    def int_between(min, max)
      range = max - min
      range < 1 ? min : (min + int(range + 1))
    end

    # Returns element of a collection chosen by tournament selection.
    # A block must be passed to the method - it should expect
    # two randomly chosen contestants from the collection and should
    # return the successful contestant. The number of tournaments will
    # generally be specified but will default to 1 if not.
    def tournament_select(collection, tournament_size: 1)
      winner = choice(collection)
      (tournament_size - 1).times do
        contender = choice(collection)
        winner = yield contender, winner
      end
      winner
    end

  end
end

class Array

  # Returns a shuffled copy of array.
  # Now implemented in Ruby core.
  # def shuffle!
  #   CX::Util::Random.instance.shuffle!(self)
  # end

  # Returns a shuffled copy of array.
  # Now implemented in Ruby core.
  # def shuffle
  #   CX::Util::Random.instance.shuffle(self)
  # end

  # Returns an element of the array chosen by
  # tournament selection using given block.
  def tournament_select(tournament_size: 1, &block)
    CX::Util::Random.instance.tournament_select(self, tournament_size: tournament_size, &block)
  end

  # Returns randomly chosen element of array.
  def random_choice
    CX::Util::Random.instance.choice(self)
  end

  # A lucky dip is a random choice or vice versa.
  alias lucky_dip random_choice

  # Returns randomly chosen element of collection or nil.
  def random_choice_or_nil
    CX::Util::Random.instance.choice_or_nil(self)
  end
end