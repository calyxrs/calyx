module Calyx::Objects
  class ObjectManager
    attr :objects
   
    def initialize
      @objects = []
    end
  end
  
  class Object
    attr_accessor :id
    attr_accessor :location
    attr_accessor :face
    attr_accessor :delay
    
    attr :type
    attr :orig_id
    attr :orig_location
    attr :orig_face
    
    def initialize(id, location, face, type, orig_id, orig_location, orig_face, delay)
      @id = id
      @location = location
      @face = face
      @type = type
      
      @orig_id = orig_id
      @orig_location = orig_location
      @orig_face = orig_face
      
      @delay = delay
    end

    def change(player = nil)
      if player != nil
        # Remove old object if the new object is in a new location
        if @location != @orig_location
          player.io.send_replace_object(@orig_location, player.last_location, -1, @face, @type)
        end
        
        # Create the new object for the specific player
        player.io.send_replace_object(@location, player.last_location, @id, @face, @type)
        return
      end
      
      WORLD.region_manager.get_local_players(@location).each {|p|
        # Remove old object if the new object is in a new location
        if @location != @orig_location
            p.io.send_replace_object(@orig_location, p.last_location, -1, @face, @type)
        end
        
        # Create the new object for all local players
        p.io.send_replace_object(@location, p.last_location, @id, @face, @type)
      }
    end
    
    def reset(player = nil)
      if player != nil
         # Remove object if the object was in a new location
         if @location != @orig_location
           player.io.send_replace_object(@location, player.last_location, -1, @orig_face, @type)
         end
         
         # Reset the object back to it's original state
         player.io.send_replace_object(@orig_location, player.last_location, @orig_id, @orig_face, @type)
         return
       end
       
       
       WORLD.region_manager.get_local_players(@location).each {|p|
         # Remove object if the object was in a new location
         if @location != @orig_location
           p.io.send_replace_object(@location, p.last_location, -1, @orig_face, @type)
         end
         
         # Create the new object for all local players
         p.io.send_replace_object(@orig_location, p.last_location, @orig_id, @orig_face, @type)
       }
    end
  end
  
  class ObjectEvent < Calyx::Engine::Event
     def initialize()
       super(1000)
     end
     
     def execute
       WORLD.object_manager.objects.each {|object|
         object.delay -= 1
         
         if object.delay <= 0
           object.reset
           
           WORLD.object_manager.objects.delete object
         end
       }
     end
   end
end
