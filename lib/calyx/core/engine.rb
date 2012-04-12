module Calyx::Engine
  class EventManager
    def initialize
      @scheduler = Rufus::Scheduler::PlainScheduler.start_new
    end
     
    def submit(event)
      submit_delayed event, event.delay
    end
     
    private
     
    def submit_delayed(event, delay)
      @scheduler.in("#{delay}") {|job|
        start = Time.now
         
        if event.running
          resubmit = true
          
          begin
            event.execute
          rescue Exception => e
            log = Logging.logger['exec']
            log.error "Error processing event"
            log.error e
            job.unschedule
            resubmit = false
          end
          
          if resubmit
            elapsed = Time.now - start
            remaining = event.delay - elapsed
            remaining = 0 if remaining <= 0
            submit_delayed event, remaining.round
          end
        else
          job.unschedule
        end
      }
    end
  end
  
  # Represents a task that is executed in the future, once or periodically.
  class Event
    # The delay in milliseconds.
    attr :delay
    
    # Whether or not the event is currently running.
    attr :running
    
    # Create an event with a specified delay.
    def initialize(delay)
      @delay = delay
      @running = true
    end
    
    # Stops the event from running in the future.
    def stop
      @running = false
    end
    
    # Called when the event is run.
    def execute
      raise "Event.execute is abstract"
    end
  end
    
  class QueuePolicy
    # This indicates actions will always be queued.
    ALWAYS = 1
    
    # This indicates actions will never be queued.
    NEVER = 2
  end
  
  class WalkablePolicy
    # This indicates actions may occur while walking.
    WALKABLE = 1
    
    # This indicates actions cannot occur while walking.
    NON_WALKABLE = 2
    
    # This indicates actions can continue while following.
    FOLLOW = 3
  end
  
  # An Event used for handling game actions.
  class Action < Event
    attr :player
    
    # Creates a new action for the player, with a specified delay.
    def initialize(player, delay)
      super delay
      @player = player
    end
    
    # Gets the queue policy of this action.
    def queue_policy
      raise "queue_policy is abstract"
    end
    
    # Gets the walkable policy of this action.
    def walkable_policy
      raise "walkable_policy is abstract"
    end
    
    # Stops the action from running.
    def stop
      super
      @player.action_queue.next_action
    end
  end
  
  # Stores a queue of pending actions.
  class ActionQueue
    @@max_size = 28
    
    # A queue of Action objects.
    attr :queue
    
    # The current Action being processed.
    attr :current_action
    
    # Creates an empty action queue.
    def initialize
      @queue = []
      @current_action = nil
    end
    
    # Cancels all queued action events.
    def cancel
      @queue.each {|action|
        action.stop
      }
      @queue.clear
      unless @current_action == nil
        @current_action.stop
        @current_action = nil
      end
    end
    
    # Adds an Action to the queue.
    def add(action)
      return if @queue.size >= @@max_size
      
      if action.queue_policy == QueuePolicy::NEVER
        size = @queue.size + (@current_action == nil ? 0 : 1)
        return if size > 0
      end
      
      @queue << action
      next_action
    end
    
    # Purges actions in the queue with a WalkablePolicy of NON_WALKABLE.
    def clear_non_walkable
      if @current_action != nil and @current_action.walkable_policy != WalkablePolicy::WALKABLE
        @current_action.stop
        @current_action = nil
      end
      
      @queue.each {|action|
        if action.walkable_policy != WalkablePolicy::WALKABLE
          action.stop
          @queue.delete action
        end
      }
    end
    
    # Processes next action.
    def next_action
      unless @current_action == nil
        @current_action = nil unless @current_action.running
      end
      
      if @queue.size > 0
        @current_action = @queue.shift
        WORLD.submit_event @current_action
      end
    end
  end
end
