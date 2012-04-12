module Calyx::Net
  class ActionSender
    SIDEBAR_INTERFACES = [
      [1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 0],
      [3917, 638, 3213, 1644, 5608, 1151, 5065, 5715, 2449, 4445, 147, 6299, 2423]
    ]
    
    attr :player
    
    def initialize(player)
      @player = player
    end
    
    def send_login
      send_details
      
      # temp
      send_message("Welcome to Calyx.");
      
      send_map_region
      send_skills
      
      send_interaction_option "Trade", 2, true
      send_interaction_option "Follow", 3, true
      
      self
    end
    
    # Log the player out.
    def send_logout
      @player.connection.send_data PacketBuilder.new(109).to_packet
      self
    end
    
    # Send the initial login details.
    def send_details
      @player.connection.send_data PacketBuilder.new(249).add_byte_a(1).add_leshort_a(player.index).to_packet
      @player.connection.send_data PacketBuilder.new(107).to_packet
      self
    end
    
    # Send map region.
    def send_map_region
      @player.last_location = player.location
      @player.connection.send_data PacketBuilder.new(73).add_short_a(@player.location.get_region_x + 6).add_short(@player.location.get_region_y + 6).to_packet
      self
    end
    
    # Send player a message in chatbox.
    def send_message(message)
      @player.connection.send_data PacketBuilder.new(253, :VAR).add_str(message).to_packet
      self
    end
    
    # Update all player skills.
    def send_skills
      Calyx::Player::Skills::SKILLS.each {|s|
        send_skill s
      }
      self
    end
    
    # Send a specific skill update.
    def send_skill(skill)
      bldr = PacketBuilder.new(134)
      bldr.add_byte Calyx::Player::Skills::SKILLS.index(skill)
      bldr.add_int1 @player.skills.exps[skill]
      bldr.add_byte @player.skills.skills[skill]
      
      @player.connection.send_data bldr.to_packet
      self
    end
    
    # Open an interface on the client.
    def send_interface(id, walkable = false)
      bldr = PacketBuilder.new(walkable ? 208 : 97)
      
      if walkable 
        bldr.add_leshort id 
      else 
        bldr.add_short id
      end
      
      @player.connection.send_data bldr.to_packet
      self
    end
    
    # Send an interface within the inventory interface.
    def send_interface_inventory(interface_id, inv_id)
      @player.interface_state.interface_opened interface_id
      @player.connection.send_data PacketBuilder.new(248).add_short_a(interface_id).add_short(inv_id).to_packet
    end

    # Send a model within an interface.
    def send_interface_model(id, zoom, model)
      @player.connection.send_data PacketBuilder.new(246).add_leshort(id).add_short(zoom).add_short(model).to_packet
      self
    end
    
    # Send a chatbox interface.
    def send_chat_interface(id)
      @player.connection.send_data PacketBuilder.new(164).add_leshort(id).to_packet
      self
    end
    
    # Send sidebar interfaces.
    def send_sidebar_interfaces
      SIDEBAR_INTERFACES[0].each_with_index {|e, index|
        send_sidebar_interface(SIDEBAR_INTERFACES[0][index], SIDEBAR_INTERFACES[1][index])
      }
      
      self
    end
    
    # Send a specific sidebar interface.
    def send_sidebar_interface(icon, id)
      @player.connection.send_data PacketBuilder.new(71).add_short(id).add_byte_a(icon).to_packet
      self
    end
    
    # Send amount interface.
    def send_amount_interface
      @player.connection.send_data PacketBuilder.new(27).to_packet
      self
    end
    
    # Clear the screen from all interfaces.
    def send_clear_screen
      @player.connection.send_data PacketBuilder.new(219).to_packet
      self
    end
    
    # Add an option for interactions.
    def send_interaction_option(option, slot, top)
      bldr = PacketBuilder.new(104, :VAR)
      bldr.add_byte_c slot
      bldr.add_byte_a(top ? 0 : 1)
      bldr.add_str option
      
      @player.connection.send_data bldr.to_packet
      self
    end
    
    # Send a string replacement.
    def send_string(id, string)
      @player.connection.send_data PacketBuilder.new(126, :VARSH).add_str(string).add_short_a(id).to_packet
      self
    end

    # Create a ground item.
    def send_grounditem_creation(item)
      x = item.location.x - (@player.last_location.get_region_x * 8)
      y = item.location.y - (@player.last_location.get_region_y * 8)
      
      @player.connection.send_data PacketBuilder.new(85).add_byte_c(y).add_byte_c(x).to_packet
      @player.connection.send_data PacketBuilder.new(44).add_leshort_a(item.item.id).add_short(item.item.count).add_byte(0).to_packet
      
      self
    end
    
    # Remove a ground item.
    def send_grounditem_removal(item)
      x = item.location.x - (@player.last_location.get_region_x * 8)
      y = item.location.y - (@player.last_location.get_region_y * 8)
      
      @player.connection.send_data PacketBuilder.new(85).add_byte_c(y).add_byte_c(x).to_packet
      @player.connection.send_data PacketBuilder.new(156).add_byte_s(0).add_short(item.item.id).to_packet
      
      self
    end
    
    # Send updates to a group of items.
    def send_update_items(interface, items)
      bldr = PacketBuilder.new(53, :VARSH)
      bldr.add_short interface
      bldr.add_short items.size
      
      items.each {|item|
        if item != nil
          count = item.count
          if count > 254
            bldr.add_byte 255
            bldr.add_int2 count
          else
            bldr.add_byte count
          end
          bldr.add_leshort_a (item.id + 1)
        else
          bldr.add_byte 0
          bldr.add_leshort_a 0
        end
      }
      
      @player.connection.send_data bldr.to_packet
      
      self
    end
    
    # Send an update to mutliple items, but not all.
    def send_update_some_items(interface, slots, items)
      bldr = PacketBuilder.new(34, :VARSH).add_short(interface)
      slots.each {|slot|
        item = items[slot]
        bldr.add_smart slot
        
        if item != nil
          bldr.add_short (item.id + 1)
          count = item.count
          if count > 254
            bldr.add_byte 255
            bldr.add_int count
          else
            bldr.add_byte count
          end
        else
          bldr.add_short 0
          bldr.add_byte 0
        end
      }
      
      @player.connection.send_data bldr.to_packet
      
      self
    end
    
    # Sends an update to a single item.
    def send_update_item(interface, slot, item)
      bldr = PacketBuilder.new(34, :VARSH)
      bldr.add_short interface
      bldr.add_smart slot
      
      if item != nil
        bldr.add_short (item.id + 1)
        count = item.count
        if count > 254
          bldr.add_byte 255
          bldr.add_int count
        else
          bldr.add_byte count
        end
      else
        bldr.add_short 0
        bldr.add_byte 0
      end
      
      @player.connection.send_data bldr.to_packet
      self
    end
    
	  # Replace an object within the world.
    def send_replace_object(loc, rel, new_id, face, type)
      # Face: 0 = WEST, -1 = NORTH, -2 = EAST, -3 = SOUTH
      # Type: 0-3 = Wall Objects, 4-8 = Wall Deco., 9 = Diag. Walls,
      #       10-11 = World Objects, 12-21 = Roofs, 22 = Floor Deco.
      
      bldr = PacketBuilder.new(60, :VARSH)
      
      # Location to modify
      bldr.add_byte (loc.y - (rel.get_region_y * 8))
      bldr.add_byte_c (loc.x - (rel.get_region_x * 8))
        
      # Delete object
      bldr.add_byte 101
      bldr.add_byte_c ((type << 2) + (face & 3))
      bldr.add_byte 0
      
      # Place object
      if new_id != -1
        bldr.add_byte 151
        bldr.add_byte_s 0
        bldr.add_leshort new_id
        bldr.add_byte_s ((type << 2) + (face & 3))
      end
      
      @player.connection.send_data bldr.to_packet
      
      self
    end
    
    # Start system update countdown.
    def send_system_update(time)
      @player.connection.send_data PacketBuilder.new(114).add_leshort(5 * time / 3).to_packet
      self
    end
    
    def send_config(id, value)
      @player.connection.send_data PacketBuilder.new(36).add_leshort(id).add_byte(value).to_packet
      self
    end
  end
end
