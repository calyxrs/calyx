module Calyx::Tasks
  class UpdateEvent < Calyx::Engine::Event
    def initialize
      super(600)
    end
    
    def execute
      ticks = []
      updates = []
      resets = []
        
      WORLD.npcs.each {|npc|
        ticks << NPCTickTask.new(npc)
        resets << NPCResetTask.new(npc)
      }
    
      WORLD.players.each {|p|
        next unless p.index
        ticks << PlayerTickTask.new(p)
        resets << PlayerResetTask.new(p)
        updates << PlayerUpdateTask.new(p)
        updates << NPCUpdateTask.new(p)
      }

      ticks.each {|t|
        WORLD.submit_task &t.method(:execute)
      }
      
      updates.each {|t|
        WORLD.submit_task &t.method(:execute)
      }
      
      resets.each {|t|
        WORLD.submit_task &t.method(:execute)
      }
    end
  end
end
