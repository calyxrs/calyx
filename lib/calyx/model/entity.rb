module Calyx::Model
  class Entity
    DEFAULT_LOCATION = Calyx::Model::Location.new 2887, 10224, 0
    
    # Info
    attr :id
    attr :flags
    attr :agressor
    attr :cool_downs
    attr :local_players
    attr :local_npcs
    attr_accessor :index
    
    # Location
    attr_reader :location
    attr_accessor :last_location
    attr :region
    attr_accessor :region_change
    attr_accessor :teleporting
    attr_accessor :teleport_location
    attr :walking_queue
    attr :facing
    
    # Combat
    attr :damage
    attr :dead
    attr :in_combat
    attr :auto_retaliate
    
    # Animations
    attr_accessor :walkanim
    attr_accessor :standanim
    
    # Misc
    attr_accessor :animation
    attr_accessor :graphic
    attr_accessor :sprites
    attr :interacting_entity
    attr :forced_chat_msg
    
    attr_accessor :cached_update
    
    def initialize
      @flags = Calyx::Misc::Flags.new
      @agressor = false
      @cool_downs = Calyx::Misc::Flags.new
      @local_players = []
      @local_npcs = []
      @sprites = Array.new(2, -1)
      
      @location = DEFAULT_LOCATION
      @last_location = @location
      @region_change = false
      @teleporting = false
      @walking_queue = Calyx::World::Pathfinder.new self
      
      @forced_chat_msg = ""
      
      @standanim = 0x328
      @walkanim = 0x333
      
      @damage = Damage.new
      @dead = false
      @in_combat = false
      @auto_retaliate = true
    end
    
    def face(location)
      @facing = location
      @flags.flag :face_coord
    end
    
    def reset_face
      @facing = nil
      @flags.set :face_coord, false
    end
    
    def interacting_entity=(entity)
      @interacting_entity = entity
      @flags.flag :face_entity
    end
    
    def reset_interacting_entity
      @interacting_entity = nil
      @flags.flag :face_entity
    end
    
    def play_animation(animation)
      @animation = animation
      @flags.flag :animation
    end
    
    def play_graphic(graphic)
      @graphic = graphic
      @flags.flag :graphics
    end
    
    def force_chat(msg)
      @forced_chat_msg = msg
      @flags.flag :forced_chat
    end
    
    def location=(location)
      @location = location
      
      region = WORLD.region_manager.get_region_for_location location
      
      return if region == nil
      remove_from_region @region unless @region == nil
      
      @region = region
      add_to_region @region
    end
    
    def add_to_region(region)
      raise "add_to_region is abstract"
    end
    
    def remove_from_region(region)
      raise "remove_to_region is abstract"
    end
    
    def destroy
      remove_from_region @region
    end
    
    def reset
      @animation = nil
      @graphic = nil
    end
  end
end
