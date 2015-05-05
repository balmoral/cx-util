require 'cx/util/observable'
require 'cx/util/thread'

module CX
  class Notifier
    include CX::Observable

    # If topics is nil it indicates interests in all topics.
    # If id is nil, then observer is not identified.
    def initialize(source, topics = nil, observer_id =  nil)
      @source = source
      @topics = topics
      @source.add_observer(self, :update)
      @id = observer_id
    end

    attr_reader :topics, :id

    # Creates a thread and passes on the update to observers
    def update(source, topic, arg_id, *args)
      if (id.nil? || arg_id.nil? || id == arg_id) && (topics.nil? || topics.include?(topic))
        thread_notify(source, topic, arg_id, *args)
      end
    end
  end
end
