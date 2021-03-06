require 'cx/util/thread'

#
# A thread safe and multi-threading version of standard Ruby Observer
# Implementation of the _Observer_ object-oriented design pattern.  The
# following documentation is copied, with modifications, from "Programming
# Ruby", by Hunt and Thomas; http://www.rubycentral.com/book/lib_patterns.html.
#
# See Observable for more info.

# The Observer pattern (also known as publish/subscribe) provides a simple
# mechanism for one object to inform a set of interested third-party objects
# when its state changes.
#
# == Mechanism
#
# The notifying class mixes in the +Observable+
# module, which provides the methods for managing the associated observer
# objects.
#
# The observers must implement a method called +update+ to receive
# notifications.
#
# The observable object must:
# * assert that it has +#changed+
# * call +#notify_observers+
#
# === Example
#
# The following example demonstrates this nicely.  A +Ticker+, when run,
# continually receives the stock +Price+ for its <tt>@symbol</tt>.  A +Warner+
# is a general observer of the price, and two warners are demonstrated, a
# +WarnLow+ and a +WarnHigh+, which print_table a warning if the price is below or
# above their set limits, respectively.
#
# The +update+ callback allows the warners to run without being explicitly
# called.  The system is set up with the +Ticker+ and several observers, and the
# observers do their duty without the top-level code having to interfere.
#
# Note that the contract between publisher and subscriber (observable and
# observer) is not declared or enforced.  The +Ticker+ publishes a time and a
# price, and the warners receive that.  But if you don't ensure that your
# contracts are correct, nothing else can warn you.
#
#   require "observer"
#
#   class Ticker          ### Periodically fetch a stock price.
#     include Observable
#
#     def initialize(symbol)
#       @symbol = symbol
#     end
#
#     def run
#       lastPrice = nil
#       loop do
#         price = Price.fetch(@symbol)
#         print_table "Current price: #{price}\n"
#         if price != lastPrice
#           changed                 # notify observers
#           lastPrice = price
#           notify_observers(Time.now, price)
#         end
#         sleep 1
#       end
#     end
#   end
#
#   class Price           ### A mock class to fetch a stock price (60 - 140).
#     def Price.fetch(symbol)
#       60 + rand(80)
#     end
#   end
#
#   class Warner          ### An abstract observer of Ticker objects.
#     def initialize(ticker, limit)
#       @limit = limit
#       ticker.add_observer(self)
#     end
#   end
#
#   class WarnLow < Warner
#     def update(time, price)       # callback for observer
#       if price < @limit
#         print_table "--- #{time.to_s}: Price below #@limit: #{price}\n"
#       end
#     end
#   end
#
#   class WarnHigh < Warner
#     def update(time, price)       # callback for observer
#       if price > @limit
#         print_table "+++ #{time.to_s}: Price above #@limit: #{price}\n"
#       end
#     end
#   end
#
#   ticker = Ticker.new("MSFT")
#   WarnLow.new(ticker, 80)
#   WarnHigh.new(ticker, 120)
#   ticker.run
#
# Produces:
#
#   Current price: 83
#   Current price: 75
#   --- Sun Jun 09 00:10:25 CDT 2002: Price below 80: 75
#   Current price: 90
#   Current price: 134
#   +++ Sun Jun 09 00:10:25 CDT 2002: Price above 120: 134
#   Current price: 134
#   Current price: 112
#   Current price: 79
#   --- Sun Jun 09 00:10:25 CDT 2002: Price below 80: 79

module CX
  module Observable

    #
    # Add +observer+ as an observer on this object. so that it will receive
    # notifications.
    #
    # +observer+:: the object that will be notified of changes.
    # +func+:: Symbol naming the method that will be called when this Observable
    #          has changes.
    #
    #          This method must return true for +observer.respond_to?+ and will
    #          receive <tt>*arg</tt> when #notify_observers is called, where
    #          <tt>*arg</tt> is the value passed to #notify_observers by this
    #          Observable

    def add_observer(observer, func = :update)
      # puts "#{self.class.name}#add_observer(#{observer.class.name}, #{func})"
      sync_peers do |peers|
        if observer.respond_to? func
          peers[observer] = func
        else
          cx_error __method__, "observer: #{observer} does not respond to #{func.to_s}"
        end
      end
      # puts "#{self.class.name}#add_observer(#{observer.class.name}, #{func}) n_observer #{observer_peers.size}"
    end

    #
    # Remove +observer+ as an observer on this object so that it will no longer
    # receive notifications.
    #
    # +observer+:: An observer of this Observable
    def delete_observer(observer)
      sync_peers do |peers|
        peers.delete observer
      end
    end

    #
    # Remove all observers associated with this object.
    #
    def delete_observers
      sync_peers do |peers|
        peers.clear
      end
    end

    #
    # Return the number of observers associated with this object.
    #
    def count_observers
      sync_peers { |peers| peers.size }
    end

    # Set the changed state of this object.  Notifications will be sent only if
    # the changed +state+ is +true+.
    #
    # +state+:: Boolean indicating the changed state of this Observable.
    #
    def changed(state=true)
      @observer_state = state
    end

    #
    # Returns true if this object's state has been changed since the last
    # #notify_observers call.
    #
    def changed?
      if defined? @observer_state and @observer_state
        true
      else
        false
      end
    end

    # Notify observers only if state has changed.
    # No threading.
    def notify_observers(*arg)
      __notify_observers(false, false, *arg)
    end

    # Notify observers regardless of change state.
    # No threading.
    def force_notify_observers(*arg)
      __notify_observers(false, true, *arg)
    end

    # Notify observers regardless of change state.
    # Create a thread for each observer notification.
    def thread_notify_observers(*arg)
      __notify_observers(true, true, *arg)
    end

    alias_method :notify,        :notify_observers
    alias_method :force_notify,  :force_notify_observers
    alias_method :thread_notify, :thread_notify_observers

    #
    # Notify observers of a change in state *if* this object's changed state is
    # +true+.
    #
    # This will invoke the method named in #add_observer, passing <tt>*arg</tt>.
    # The changed state is then set to +false+.
    #
    # <tt>*arg</tt>:: Any arguments to pass to the observers.

    private

    def __notify_observers(threaded, force, *arg)
      # puts "#{self.class.name}#__notify_observers(thread: #{threaded}, force: #{force}, *arg: ...) n_observers = #{observer_peers.size}"
      sync_peers do |_peers|
        changed = defined?(@observer_state) && @observer_state
        if force || changed
          _peers.each { |peer, accessor|
            if threaded
              Thread.new { peer.send accessor, *arg }
            else
              peer.send accessor, *arg
            end
          }
        end
      end
    end

    def observer_peers
      # risk not syncing to avoid double sync (if object already sync'd)
      if !defined?(@observer_peers) || @observer_peers.nil?
        # puts "#{self.class.name}#observer_peers :: creating new hash "
        @observer_peers = {}
      end
      @observer_peers
    end

    def sync_peers
      observer_peers.sync {
        # puts "#{self.class.name}#sync_peers :: calling yields on #{observer_peers.size} observer_peers "
        yield observer_peers
      }
    end

  end
end
