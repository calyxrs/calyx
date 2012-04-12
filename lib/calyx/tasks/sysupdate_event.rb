module Calyx::Tasks
  class SystemUpdateEvent < Calyx::Engine::Event
    attr :state
    attr :seconds
  
    def initialize(seconds)
      super(0)
      @seconds = seconds
      @state = :wait
    end
    
    def execute
      case @state
      when :wait
        wait
      when :kick
        kick
      when :wait_for_saves
        wait_for_saves
      end
    end
    
    def wait
      @state = :kick
      @delay = @seconds * 1000
      
      WORLD.players.each {|p|
        p.io.send_system_update @seconds
      }
    end
    
    def kick
      # Disallow logins
      SERVER.updatemode = true
    
      # Kick all users
      WORLD.players.delete_if {|p|
        WORLD.unregister(p, false)
        true
      }
      
      @state = :wait_for_saves
      @delay = 1000
    end
    
    def wait_for_saves
      log = Logging.logger['sysupdate']
    
      if WORLD.work_thread.busy
        log.warn "Waiting for profiles to save..."
      else
        log.warn "Shutting down"
        stop
        Kernel.exit!
      end
    end
  end
end
