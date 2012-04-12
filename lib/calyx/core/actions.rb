module Calyx::Actions
  class HarvestingAction < Calyx::Engine::Action
    attr :loc
  
    def initialize(player, loc)
      super(player, 0)
      @loc = loc
      @total_cycles = 0
      @cycles = 0
    end
    
    def queue_policy
      Calyx::Engine::QueuePolicy::NEVER
    end
    
    def walkable_policy
      Calyx::Engine::WalkablePolicy::NON_WALKABLE
    end
    
    def init
      raise "init is abstract"
    end
    
    def harvest_delay
      raise "harvest_delay is abstract"
    end
    
    def cycles
      raise "cycles is abstract"
    end
    
    def factor
      raise "factor is abstract"
    end
    
    def harvested_item
      raise "harvested_item is abstract"
    end
    
    def experience
      raise "experience is abstract"
    end
    
    def skill
      raise "skill is abstract"
    end
    
    def animation
      raise "animation is abstract"
    end
    
    def periodic_rewards
      raise "periodic_rewards is abstract"
    end
    
    def execute
      if @delay == 0
        @delay = harvest_delay
        init
        
        if @running
          player.play_animation animation
          player.face @loc
        end
        
        @cycles = cycles
        @total_cycles = @cycles
      else
        @cycles -= 1
        item = harvested_item
        
        if player.inventory.has_room_for item
          give_rewards(item) if (@total_cycles == 1 || rand > factor) && periodic_rewards
        else
          stop
          player.io.send_message "There is not enough space in your inventory."
          return
        end
        
        if @cycles == 0
          # TODO Replace with expired object
          give_rewards item unless periodic_rewards
          stop
        else
          player.play_animation animation
          player.face @loc
        end
      end
    end
    
    def give_rewards(reward)
		  @player.inventory.add reward
		  @player.io.send_message "You get some #{reward.definition.name}."
		  @player.skills.add_exp(skill, experience)
    end
  end
end
