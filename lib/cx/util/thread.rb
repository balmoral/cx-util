# Evaluate the given block with a lock on given object.
# e.g. synchronized(some_object) { do_something }
# Provides java-like synchronization on an object.
# We provide a cleaner alternative in Object
# extensions below: Object#sync { ... }
def synchronized(o)
  o.mutex.synchronize { yield }
end

# The Object.mutex method defined above needs to lock the class
# if the object doesn't have a Mutex yet. If the class doesn't have
# its own Mutex yet, then the class of the class (the Class object)
# will be locked. In order to prevent infinite recursion, we must
# ensure that the Class object has a Mutex. The following code will
# be executed the first time this script is loaded.
Class.instance_eval { @__mutex = Mutex.new }


# global mutex for synchronizing puts
$__puts_mutex__ = Mutex.new

# global max enumeration threads
$__max_enum_threads__ = 16

class Object
  # Evaluate the given block with sync lock on self.
  # Same as but simpler than synchronized(object)
  # especially when calling from self.
  def thread_sync
    mutex.synchronize { yield }
  end

  def no_thread_sync
    yield
  end

  # Returns a mutex for synchronizing this object.
  # Some tricks to allow lazy instantiation to
  # to work thread-safely. For background see:
  #   David Flanagan & Yukihiro Matsumotu,
  #   "The Ruby Programming Language" 2008,
  #   section 8.8.2 (pp283ff)
  def mutex
    return @__mutex if @__mutex
    synchronized(self.class) {
      # check again: by the time we get into this synchronized block
      # some other thread might have already created the mutex.
      @__mutex = @__mutex || Mutex.new
    }
  end

  def puts_sync(s)
    Thread.new{$__puts_mutex__.synchronize{puts s}}
  end
end

class Integer
  def thread_times
    n_threads = self.min($__max_enum_threads__)
    threads = []
    times do |i|
      threads << Thread.new do
        yield(i)
      end
      if threads.size == n_threads
        threads.each { |t| t.join }
        threads.clear
      end
    end
    threads.each { |t| t.join }
  end

  def thread_upto(limit)
    n_threads = (limit - self + 1).min($__max_enum_threads__)
    threads = []
    upto(limit) do |i|
      threads << Thread.new do
        yield(i)
      end
      if threads.length == n_threads
        threads.each { |t| t.join }
        threads.clear
      end
    end
    threads.each { |t| t.join }
  end

  def thread_downto(limit)
    n_threads = (self - limit + 1).min($__max_enum_threads__)
    threads = []
    downto(limit) do |i|
      threads << Thread.new do
        yield(i)
      end
      if threads.length == n_threads
        threads.each { |t| t.join }
        threads.clear
      end
    end
    threads.each { |t| t.join }
  end
end

module Enumerable
   # Be sure to synchronize as appropriate in block.
   # Uses Enumerable#each_with_index but only
   # passes index to block if with_index is true.
   def thread_each(with_index: false)
     threads = []
     max_threads = $__max_enum_threads__
     each_with_index do |e, i|
       threads << Thread.new do
         with_index ? yield(e, i) : yield(e)
       end
       if threads.length == max_threads
         threads.each { |t| t.join }
         threads.clear
       end
     end
     threads.each { |t| t.join }
   end

   # Be sure to synchronize as appropriate in block
   def thread_collect
     collection = Array.new
     thread_each do |e|
       collection << yield(e)
     end
     collection
   end

  # Be sure to synchronize as appropriate in block.
  def thread_select
    selection = Array.new
    thread_each do |e|
     selection << e if yield(e)
  end
    selection
  end
end

class Hash
  # Be sure to synchronize as appropriate in block.
  # Calls block with each key and value.
  def thread_each
    threads = []
    max_threads = $__max_enum_threads__
    each do |k, v|
      threads << Thread.new do
        yield(k, v)
      end
      if threads.length == max_threads
        threads.each { |t| t.join }
        threads.clear
      end
    end
    threads.each { |t| t.join }
  end
end # Hash