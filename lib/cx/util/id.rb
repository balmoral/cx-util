require 'cx/util/thread'

module CX
  class Id

    def initialize(start_id = -1)
      start(start_id)
    end

    def current
      sync { @id }
    end

    def next
      sync { @id += 1 }
    end

    def start(id)
      sync { @id = id }
    end

  end
end
