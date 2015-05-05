module CX
  module Sort

    # Insert an object into an array using sort block to maintain ordering
    # assumes array is sorted in conformity with sort block
    # block should expect |obj,ary[i]| and return one of -1,0,1
    # insertion will occur at index of first block return equal to 1
    # (or appended to the array if no 1 is returned by block)
    # to maintain reverse order the block should swap 1,-1
    def insert_sort(target, ary, ary_size_limit = nil, &block)
      if ary.size == 0
        ary << target
      else
        ix = find_index_sort_ge(target, ary, &block)
        if ix
          ary.insert(ix, target)
          ary.pop if ary_size_limit && ary.size > ary_size_limit
        elsif ary_size_limit.nil? || ary.size < ary_size_limit
          ary << target
        end
      end
    end

    def find_index_sort_eq(target, ary, &block)
      find_index_sort_between(target, ary, 0, ary.size - 1, 0, &block)
    end

    def find_sort_eq(target, ary, &block)
      i = find_index_sort_eq(target, ary, &block)
      i ? ary[i] : nil
    end

    def find_index_sort_ge(target, ary, &block)
      find_index_sort_between(target, ary, 0, ary.size - 1, 1, &block)
    end

    def find_sort_ge(target, ary, &block)
      i = find_index_sort_ge(target, ary, &block)
      i ? ary[i] : nil
    end

    def find_index_sort_le(target, ary, &block)
      find_index_sort_between(target, ary, 0, ary.size - 1, -1, &block)
    end

    def find_sort_le(target, ary, &block)
      i = find_index_sort_le(target, ary, &block)
      i ? ary[i] : nil
    end

    protected

    def find_index_sort_between(target, ary, first_index, last_index, match, &block)
      assert( first_index <= last_index )
      assert( first_index >= 0 )
      assert( first_index < ary.size )
      assert( last_index >= 0 )
      assert( last_index < ary.size )
      mid_index = ((first_index + last_index) / 2).to_i
      cmp = yield(target, ary[mid_index])
      if cmp == 0
        mid_index
      elsif cmp > 0
        if mid_index > first_index
          find_index_sort_between(target, ary, first_index, mid_index - 1, match, &block)
        else
          match > 0 ? mid_index : nil
        end
      else
        if mid_index < last_index
          find_index_sort_between(target, ary, mid_index + 1, last_index, match, &block)
        else
          match < 0 ? mid_index : nil
        end
      end
    end

  end
end