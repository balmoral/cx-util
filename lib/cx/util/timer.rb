module CX
  class Timer

    attr_reader :start_time

    def initialize(&block)
      @start_time = @finish_time = Time.now
      time(&block) if block
    end

    def start
     @start_time = Time.now
     self
    end

    def finish
      @finish_time = Time.now
      self
    end

    # Returns the time it takes to execute
    # the given block as an easily readable
    # string.
    def time(&block)
      start
      block.call
      finish
      to_s
    end

    def seconds
      if @start_time && @finish_time
        @finish_time - @start_time
      elsif @start_time
        Time.now - @start_time
      else
        0
      end
    end

    def to_s
      total_seconds = seconds
      current_hours = (total_seconds / 3600).truncate
      current_minutes = ((total_seconds - current_hours * 3600) / 60).truncate
      current_seconds = total_seconds - current_hours * 3600 - current_minutes * 60
      case
      when current_hours == 0 && current_minutes == 0
        '%0ds' % seconds
      when current_hours == 0
        '%dm%02ds' % [current_minutes, current_seconds]
      else
        '%dh%02dm%02ds' % [current_hours, current_minutes, current_seconds]
      end
    end

    # Returns the time it takes to execute
    # the given block as an easily readable
    # string.
    def self.time(&block)
      t = new(&block)
      t.to_s
    end

    def self.run(&block)
      time(&block)
    end
  end
end
    