module Calyx::Doors
  class DoorManager
    @@single_data = []
    @@double_data = []
    @@open_single_doors = [  
      1504, 1514, 1517, 1520, 1531,
      1534, 2033, 2035, 2037, 2998,
      3271, 4468, 4697, 6101,6103,
      6105, 6107, 6109, 6111, 6113,
      6115, 6976, 6978, 8696, 8819,
      10261, 10263,10265,11708,11710,
      11712,11715,11994,12445, 13002
    ]
    @@open_double_doors = [1520, 1517]
    
    def load_single_doors
      d = XmlSimple.xml_in("data/doors_single.xml")
      d["door"].each_with_index {|row, idx|
        @@single_data << 
          {
            :id => row['id'].to_i,
            :location => Calyx::Model::Location.new(row['x'].to_i, row['y'].to_i, row['z'].to_i),
            :face => row['face'].to_i,
            :type => row['type'].to_i
          }
      }
      
      @@single_data.each {|door|
        handler = HOOKS[:obj_click1][door[:id]]
        if !handler.instance_of?(Proc)
          on_obj_option(door[:id]) {|player, loc|
            return unless player.location.within_interaction_distance?(loc)
            
            player.walking_queue.reset
            handle_door door[:id], loc
          }
        end
      }
    end
    
    def load_double_doors
      d = XmlSimple.xml_in("data/doors_double.xml")
      d["door"].each_with_index {|row, idx|
       @@double_data << 
          {
           :id => row['id'].to_i,
           :location => Calyx::Model::Location.new(row['x'].to_i, row['y'].to_i, row['z'].to_i),
           :face => row['face'].to_i,
           :type => 0
          }
      }
      
      @@double_data.each {|door|
        handler = HOOKS[:obj_click1][door[:id]]
          
        if !handler.instance_of?(Proc)
          on_obj_option(door[:id]) {|player, loc|
            return unless player.location.within_interaction_distance?(loc)
            
            player.walking_queue.reset
            handle_double_door door[:id], loc
          }
        end
      }
    end
    
    def handle_door(id, loc)
      door = WORLD.object_manager.objects.find {|d| d && d.id == id && d.location == loc }
      
      if door != nil
        # Reset cause it's already changed
        door.reset
        
        WORLD.object_manager.objects.delete door
      else
        data = get_data id, loc
        return unless data != nil
      
        open = @@open_single_doors.find {|val| val == id} != nil
        
        # Change door for the first time
        WORLD.object_manager.objects << door = Door.new(data, open)
        
        # Move and rotate
        change_state door
        
        WORLD.region_manager.get_local_players(door.location, false).each {|p|
          p.io.send_replace_object(door.location, p.last_location, door.id, door.face, door.type)
        }
      end
    end
    
    def change_state(door)
      x_off = 0
      y_off = 0
      face = door.orig_face
      
      if door.type == 0
        if door.open
          face = (door.face - 1) & 3
          
          x_off = 1 if door.orig_face == 1
          x_off = -1 if door.orig_face == 3
          y_off = 1 if door.orig_face == 0
          y_off = -1 if door.orig_face == 2
        else
          face = (door.face + 1) & 3
          
          x_off = 1 if door.orig_face == 2
          x_off = -1 if door.orig_face == 0
          y_off = 1 if door.orig_face == 1
          y_off = -1 if door.orig_face == 3
        end
      elsif door.type == 9
        if door.open
          face = 3 - door.face
        else
          face = (door.face - 1) & 3
        end
        
        x_off = 1 if door.orig_face == 0 || door.orig_face == 1
        x_off = -1 if door.orig_face == 2 || door.orig_face == 3
      end
      
      if x_off != 0 || y_off != 0
        WORLD.region_manager.get_local_players(door.location, false).each {|p|
          p.io.send_replace_object(door.location, p.last_location, -1, 0, door.type)
        }
      end
      
      door.id -= 1 if door.open
      door.id += 1 if !door.open
      door.face = face
      door.location = door.location.transform x_off, y_off, 0
    end
    
    def handle_double_door(id, loc)
      door = WORLD.object_manager.objects.find {|d| d.kind_of?(DoubleDoor) && (d.id == id && d.location == loc || d.r_door_id == id && d.r_door_location == loc) }

      if door != nil
        # Reset cause it's already changed
        door.reset
        
        WORLD.object_manager.objects.delete door
      else
        data = DoorManager.get_double_data id, loc
        return unless data != nil
      
        open = @@open_double_doors.find {|val| val == id} != nil
        
        # Change door for the first time
        WORLD.object_manager.objects << door = DoubleDoor.new(data, open)
      end
    end
    
    def self.change_double_state(door)
      # Left
      x_off = 0
      y_off = 0
      face = door.orig_face
      
      if door.open
        face = 1 + door.face % 2
        
        x_off = -1 if door.orig_face == 1 || door.orig_face == 2 || door.orig_face == 3
        y_off = -1 if door.orig_face == 0
      else
        face = 2 * (-door.face/3.floor + 1) + (door.face - 1) % 2
        
        x_off = 1 if door.orig_face == 2
        x_off = -1 if door.orig_face == 0
        y_off = 1 if door.orig_face == 1
        y_off = -1 if door.orig_face == 3
      end
      
      if x_off != 0 || y_off != 0
       WORLD.region_manager.get_local_players(door.location, false).each {|p|
         p.io.send_replace_object(door.location, p.last_location, -1, 0, 0)
       }
      end
      
      door.id -= 1 if door.open
      door.id += 1 if !door.open
      door.face = face
      door.location = door.location.transform x_off, y_off, 0
      
      if door.id != nil
        WORLD.region_manager.get_local_players(door.location, false).each {|p|
          p.io.send_replace_object(door.location, p.last_location, door.id, door.face, 0)
        }
      end
      
      # Right
      x_off = 0
      y_off = 0
      face = door.r_door_orig_face
      
      if door.open
        face = 3 if door.r_door_orig_face == 0
        face = 0 if door.r_door_orig_face == 1
        face = 1 if door.r_door_orig_face == 2
        face = 2 if door.r_door_orig_face == 3
                
        x_off = 1 if door.r_door_orig_face == 0
        x_off = -1 if door.r_door_orig_face == 1 || door.r_door_orig_face == 3
        y_off = -1 if door.r_door_orig_face == 2
      else
        face = 1 if door.r_door_orig_face == 0
        face = 2 if door.r_door_orig_face == 1
        face = 3 if door.r_door_orig_face == 2
        face = 2 if door.r_door_orig_face == 3
                
        x_off = 1 if door.r_door_orig_face == 2
        x_off = -1 if door.r_door_orig_face == 0
        y_off = 1 if door.r_door_orig_face == 1
        y_off = -1 if door.r_door_orig_face == 3
      end
      
      if x_off != 0 || y_off != 0
       WORLD.region_manager.get_local_players(door.r_door_location, false).each {|p|
         p.io.send_replace_object(door.r_door_location, p.last_location, -1, 0, 0)
       }
      end
      
      door.r_door_id -= 1 if door.open
      door.r_door_id += 1 if !door.open
      door.r_door_face = face
      door.r_door_location = door.r_door_location.transform x_off, y_off, 0
      
      if door.r_door_id != nil
        WORLD.region_manager.get_local_players(door.location, false).each {|p|
          p.io.send_replace_object(door.r_door_location, p.last_location, door.r_door_id, door.r_door_face, 0)
        }
      end
    end
    
    def get_data(id, loc)
      @@single_data.find {|door| door[:id] == id && door[:location] == loc }
    end
    
    def self.get_double_data(id, loc)
      @@double_data.find {|door| door[:id] == id && door[:location] == loc }
    end
  end
  
  class Door < Calyx::Objects::Object
    attr :open
    
    def initialize(data, open = true)
      super(data[:id], data[:location], data[:face], data[:type], data[:id], data[:location], data[:face], 300)
      @open = open
    end
  end
  
  class DoubleDoor < Door
    attr_accessor :r_door_id
    attr_accessor :r_door_location
    attr_accessor :r_door_face
    
    attr :r_door_orig_id
    attr :r_door_orig_location
    attr :r_door_orig_face
    
    def initialize(data, open = true) 
      super(data, open) # Temp until it's changed below
      
      l_id_off = -3
      r_id_off = 3
      l_x_off = 0
      r_x_off = 0
      l_y_off = 0
      r_y_off = 0
      
      if open
        if data[:face] == 0
          l_x_off = -1
          r_x_off = 1
        elsif data[:face] == 1
          l_y_off = 1
          r_y_off = -1
        elsif data[:face] == 2
          l_x_off = -1
          r_y_off = -1
        elsif data[:face] == 3
          l_y_off = 1
          r_y_off = -1
        end
      else
        if data[:face] == 0
          l_y_off = -1
          r_y_off = 1
        elsif data[:face] == 1
          l_x_off = -1
          r_x_off = 1
        elsif data[:face] == 2
          l_y_off = 1
          r_y_off = -1
        elsif data[:face] == 3
          l_id_off = 3
          r_id_off = -3
          l_x_off = -1
          r_x_off = 1
        end
      end
      
      temp_l = Calyx::Model::Location.new(data[:location].x+l_x_off, data[:location].y+l_y_off, data[:location].z)
      temp_r = Calyx::Model::Location.new(data[:location].x+r_x_off, data[:location].y+r_y_off, data[:location].z)
      
      l_data = DoorManager.get_double_data((data[:id]+l_id_off), temp_l)
      r_data = DoorManager.get_double_data((data[:id]+r_id_off), temp_r)

      if l_data != nil
        @id = l_data[:id]
        @location = l_data[:location]
        @face = l_data[:face]
          
        @orig_id = @id
        @orig_location = Calyx::Model::Location.new(@location.x, @location.y, @location.z)
        @orig_face = @face
        
        # HACKS
        @r_door_id = data[:id]
        @r_door_location = data[:location]
        @r_door_face = data[:face]
          
        @r_door_orig_id = @r_door_id
        @r_door_orig_location = Calyx::Model::Location.new(@r_door_location.x, @r_door_location.y, @r_door_location.z)
        @r_door_orig_face = @r_door_face
        
        DoorManager.change_double_state self
      end
      
      if r_data != nil
        # HACKS
        @id = data[:id]
        @location = data[:location]
        @face = data[:face]
          
        @orig_id = @id
        @orig_location = Calyx::Model::Location.new(@location.x, @location.y, @location.z)
        @orig_face = @face
                
        @r_door_id = r_data[:id]
        @r_door_location = r_data[:location]
        @r_door_face = r_data[:face]
          
        @r_door_orig_id = @r_door_id
        @r_door_orig_location = Calyx::Model::Location.new(@r_door_location.x, @r_door_location.y, @r_door_location.z)
        @r_door_orig_face = @r_door_face
        
        DoorManager.change_double_state self
      end
    end
    
    def change(player)
     return unless player != nil
      
     # Delete if the new door has moved
     if @location != @orig_location
       player.io.send_replace_object(@orig_location, player.last_location, -1, 0, 0)
       player.io.send_replace_object(@r_door_orig_location, player.last_location, -1, 0, 0)
     end
     
     player.io.send_replace_object(@location, player.last_location, @id, @face, 0)
     
     player.io.send_replace_object(@r_door_location, player.last_location, @r_door_id, @r_door_face, 0)
    end
    
    def reset
      if @location != @orig_location
        # Remove the old replaced doors if they moved
        WORLD.region_manager.get_local_players(@location, false).each {|p|
          p.io.send_replace_object(@location, p.last_location, -1, 0, 0)
          p.io.send_replace_object(@r_door_location, p.last_location, -1, 0, 0)
        }
      end
      
      # Reset ids/positions/rotations
      @id = @orig_id
      @r_door_id = @r_door_orig_id
      @location = @orig_location
      @r_door_location = @r_door_orig_location
      @face = @orig_face
      @r_door_face = @r_door_orig_face
      
      # Add back to original locations
      WORLD.region_manager.get_local_players(@location, false).each {|p|
        p.io.send_replace_object(@location, p.last_location, @id, @face, 0)
        p.io.send_replace_object(@r_door_location, p.last_location, @r_door_id, @r_door_face, 0)
      }
    end
    
    def id
      @id
    end
  end
end
