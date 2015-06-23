require 'singleton'

# A simple thread safe counter.
# Can be be used as an id generator within a process.

module CX
  class Counter

    def initialize(count = -1)
      @mutex = Mutex.new
      _sync { @count = count }
    end

    def current
      _sync { @count }
    end
    
    def next
      _sync { @count += 1 }
    end

    def reset
      _sync { @count = 0 }
    end

    private
  
    def _sync
      @mutex.synchronize { yield }
    end

  end
end
