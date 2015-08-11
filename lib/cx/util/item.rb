# A simple wrapper to pair an indexed collection with an index
# and provide functionality around the an item's knowledge of where
# it is located in the collection.
#
# Implemented as both an Itemize module and Item class
# to allow flexibility in implementation.
#
# TODO: consider issue of two-way reference between collection and its items.

module Itemize

  attr_reader :collection, :index

  def initialize(collection, index)
    @collection, @index = collection, index
  end

  def value
    @collection[@index]
  end

  def prev(offset = 1)
    @collection[@index - offset]
  end

  def next(offset = 1)
    @collection[@index + offset]
  end

  def find_prev
    (@index - 1).downto(0) do |i|
      v = @collection[i]
      return self.class.new(@collection, i) if yield(v, i)
    end
    nil
  end

  def find_next
    (@index + 1).upto(@collection.size - 1) do |i|
      v = @collection[i]
      return self.class.new(@collection, i) if yield(v, i)
    end
    nil
  end

end

class Item
  include Itemize
end

