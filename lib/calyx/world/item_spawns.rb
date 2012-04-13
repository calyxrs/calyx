module Calyx::World
  class ItemSpawns
    @@items = []
    
    def ItemSpawns.load
      items = XmlSimple.xml_in("data/item_spawns.xml")
      items["item"].each_with_index {|row, idx|
        @@items << Item.new(row)
      }
      
      # TODO move out?
      WORLD.submit_event ItemEvent.new
    end

    def ItemSpawns.items
      @@items
    end
  end
  
  class ItemEvent < Calyx::Engine::Event
    def initialize()
      super(1000)
    end
    
    def execute
      ItemSpawns.items.each {|item|
        item.respawn -= 1 if item.picked_up
        
        if item.picked_up && item.respawn <= 0
          item.spawn
        end
      }
    end
  end
  
  class Item
    attr :item
    attr :location
    attr_accessor :respawn
    attr :orig_respawn
    attr :picked_up
    attr :on_table
    
    def initialize(data)
      @item = Calyx::Item::Item.new(data['id'].to_i, (data.include?('amount') ? data['amount'].to_i : 1))
      @location = Calyx::Model::Location.new(data['x'].to_i, data['y'].to_i, data['z'].to_i)
      @respawn = data.include?('respawn') ? data['respawn'].to_i : 300 # Number of seconds before it will respawn
      @orig_respawn = @respawn
      @picked_up = false
      @on_table = data.include?('ontable') && data['ontable'] == "true"
    end
    
    def remove
      @picked_up = true
      
      WORLD.region_manager.get_local_players(@location).each {|player|
        player.io.send_grounditem_removal(self)
      }
    end
    
    def spawn(player = nil)
      @picked_up = false
      @respawn = @orig_respawn
      
      if player != nil
        player.io.send_grounditem_creation(self)
        return
      end
      
      WORLD.region_manager.get_local_players(@location).each {|p|
        p.io.send_grounditem_creation(self)
      }
    end
    
    def within_distance?(player)
      player.location.within_distance? @location
    end
    
    def available
      true
    end
  end
end
