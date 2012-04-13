module Calyx::Tasks
  class PlayerTickTask
    attr :player
    
    def initialize(player)
      @player = player
    end
    
    def execute
      messages = player.chat_queue
      if messages.size > 0
        player.flags.flag :chat
        player.current_chat_message = player.chat_queue.shift
      else
        player.current_chat_message = nil
      end
      
      @player.walking_queue.next_movement
    end 
  end

  class PlayerResetTask
    attr :player
    
    def initialize(player)
      @player = player
    end
    
    def execute
      @player.flags.reset
      @player.teleporting = false
      @player.region_change = false
      @player.teleport_location = nil
      @player.cached_update = nil
      @player.animation = nil
      @player.graphic = nil
    end  
  end

  class PlayerUpdateTask
    attr :player
    
    def initialize(player)
      @player = player
    end
    
    def execute
      @player.io.send_map_region if @player.region_change
      
      update_block = Calyx::Net::PacketBuilder.new
      packet = Calyx::Net::PacketBuilder.new(81, :VARSH)
      packet.start_bit_access
      
      # Update current player
      update_this_player_movement packet
      update_player update_block, @player, false, true
      
      # Process local player list
      packet.add_bits 8, @player.local_players.size
      @player.local_players.delete_if {|p|
        should_remove = !WORLD.players.include?(p) || p.teleporting || !p.location.within_distance?(@player.location)
        
        if should_remove
          packet.add_bits 1, 1
          packet.add_bits 2, 3
        else
          update_player_movement packet, p
          update_player update_block, p, false, false if p.flags.update_required?
        end
      
        should_remove
      }
      
      # Check if we should add any new players to the list
      WORLD.region_manager.get_local_players(@player).each {|p|
        # Make sure we have space and avoid duplicates
        break if @player.local_players.size >= 255
        next if p.index == nil || p.eql?(@player) || @player.local_players.include?(p)
        
        # Add and update the new player
        @player.local_players << p
        add_new_player packet, p
        update_player update_block, p, true, false
      }
      
      unless update_block.empty?
        packet.add_bits 11, 2047
        packet.finish_bit_access
        packet.add_bytes(update_block.to_packet.buffer)
      else
        packet.finish_bit_access
      end
      
      @player.connection.send_data packet.to_packet
    end
    
    def update_player_movement(packet, p)
      sprites = p.sprites
      
      if sprites[0] == -1
        if p.flags.update_required?
          packet.add_bits 1, 1
          packet.add_bits 2, 0
        else
          packet.add_bits 1, 0
        end
      elsif sprites[1] == -1
        packet.add_bits 1, 1
        packet.add_bits 2, 1
        packet.add_bits 3, sprites[0]
        packet.add_bits 1, (p.flags.update_required? ? 1 : 0)
      else
        packet.add_bits 1, 1
        packet.add_bits 2, 2
        packet.add_bits 3, sprites[0]
        packet.add_bits 3, sprites[1]
        packet.add_bits 1, (p.flags.update_required? ? 1 : 0)
      end
    end
    
    def add_new_player(packet, p)
      packet.add_bits 11, p.index
      packet.add_bits 1, 1
      packet.add_bits 1, 1
      
      dx = p.location.x - @player.location.x
      dy = p.location.y - @player.location.y
      
      packet.add_bits 5, dy
      packet.add_bits 5, dx
    end
    
    def append_forced_move(p, block)
      block.add_byte_s p.location.get_local_x         # x1 (local)
      block.add_byte_s p.location.get_local_y         # y1 (local)
      block.add_byte_s (p.location.get_local_x + 2)   # x2 (local)
      block.add_byte_s p.location.get_local_y         # y2 (local)
      block.add_leshort_a 0                           # speed to move from current to (x1, y1)
      block.add_short_a 20                            # speed to move from (x1, y1) to (x2, y2)
      block.add_byte_s -3                             # direction
    end
    
    def append_graphics(p, block)
      block.add_leshort p.graphic.id
      block.add_int p.graphic.delay
    end
    
    def append_animation(p, block)
      block.add_leshort p.animation.id
      block.add_byte_c p.animation.delay
    end
    
    def append_forced_chat(p, block)
      block.add_str(p.forced_chat_msg)
    end
    
    def append_chat(p, block)
      msg = p.current_chat_message
      block.add_leshort((msg.color << 8).ubyte | msg.effects.ubyte)
      block.add_byte Calyx::World::RIGHTS.index(p.rights)
      block.add_byte_c msg.text.size
      block.add_bytes msg.text.reverse
    end
    
    def append_face_entity(p, block)
      block.add_leshort p.interacting_entity == nil ? -1 : p.interacting_entity.index
    end
    
    def append_appearance(p, block)
      app = p.appearance
      eq = p.equipment
      
      # Create the player properties
      props = Calyx::Net::PacketBuilder.new
      props.add_byte app.gender # gender
      props.add_byte 0 # icon
      
      if p.model != -1
        props.add_short -1
        props.add_short p.model
      else
        (0...4).each {|i|
          if eq.is_slot_used(i)
            props.add_short (0x200 + eq.items[i].id).short
          else
            props.add_byte 0
          end
        }
        
        # Chest
        if eq.is_slot_used(4)
          props.add_short (0x200 + eq.items[4].id).short
        else
          props.add_short (0x100 + app.chest).short
        end
        
        # Shield
        if eq.is_slot_used(5)
          props.add_short (0x200 + eq.items[5].id).short
        else
          props.add_byte 0
        end
        
        # Arms (shown unless a platebody is worn)
        if eq.is_slot_used(4) && Calyx::Equipment.is(eq.items[4], 10)
          props.add_short (0x200 + eq.items[4].id).short
        else
          props.add_short (0x100 + app.arms).short
        end
        
        # Legs
        if eq.is_slot_used(7)
          props.add_short (0x200 + eq.items[7].id).short
        else
          props.add_short (0x100 + app.legs).short
        end
        
        # Head (shown unless a full helm or mask is worn)
        if eq.is_slot_used(0) && (Calyx::Equipment.is(eq.items[0], 11) || Calyx::Equipment.is(eq.items[0], 12))
          props.add_byte 0
        else
          props.add_short (0x100 + app.head).short
        end
        
        # Gloves
        if eq.is_slot_used(9)
          props.add_short (0x200 + eq.items[9].id).short
        else
          props.add_short (0x100 + app.hands).short
        end
        
        # Boots
        if eq.is_slot_used(10)
          props.add_short (0x200 + eq.items[10].id).short
        else
          props.add_short (0x100 + app.feet).short
        end
        
        # Beard
        fullhelm = eq.is_slot_used(0) && (Calyx::Equipment.is(eq.items[0], 11) || Calyx::Equipment.is(eq.items[0], 12))
        
        if fullhelm || app.gender == 1
          props.add_byte 0
        else
          props.add_short (0x100 + app.beard).short
        end
      end
      
      # Colors
      props.add_byte app.hair_color
      props.add_byte app.torso_color
      props.add_byte app.leg_color
      props.add_byte app.feet_color
      props.add_byte app.skin_color
      
      # Animations
      props.add_short p.standanim # stand
      props.add_short 0x337       # stand turn
      props.add_short p.walkanim  # walk
      props.add_short 0x334       # turn 180
      props.add_short 0x335       # turn 90 cw
      props.add_short 0x336       # turn 90 ccw
      props.add_short 0x338       # run
      
      # Details
      props.add_long Calyx::Misc::NameUtils.name_to_long(p.name)
      props.add_byte p.skills.combat_level
      props.add_short 0
      
      # Add to update block
      props_packet = props.to_packet
      block.add_byte_c(props_packet.buffer.size)
      block.add_bytes(props_packet.buffer)
    end
    
    def append_face_coord(p, block)
      x = p.facing == nil ? 0 : (p.facing.x * 2 + 1)
      y = p.facing == nil ? 0 : (p.facing.y * 2 + 1)
      block.add_leshort_a x
      block.add_leshort y
    end
    
    def append_hit2(p, block)
      block.add_byte p.damage.hit2_damage
      block.add_byte_s p.damage.hit2_type
      block.add_byte p.skills.skills[3]
      block.add_byte_c p.skills.level_for_exp(3)
    end
    
    def append_hit(p, block)
      block.add_byte p.damage.hit1_damage
      block.add_byte_a p.damage.hit1_type
      block.add_byte_c p.skills.skills[3]
      block.add_byte p.skills.level_for_exp(3)
    end
    
    def update_player(packet, p, force_appearance, no_chat)
      return unless p.flags.update_required? || force_appearance
      
      # Use cached update block if one is available
      if p.cached_update != nil && !p.eql?(@player) && !force_appearance && !no_chat
        packet.add_bytes p.cached_update.buffer
        return
      end
      
      # Otherwise build a new one
      block = Calyx::Net::PacketBuilder.new
      flags = p.flags
      mask = 0
      
      # Calculate bitmask
      mask |= 0x400 if flags.get(:forced_move)
      mask |= 0x100 if flags.get(:graphics)
      mask |= 0x8   if flags.get(:animation)
      mask |= 0x4   if flags.get(:forced_chat)
      mask |= 0x80  if flags.get(:chat) && !no_chat
      mask |= 0x1   if flags.get(:face_entity)
      mask |= 0x10  if flags.get(:appearance) || force_appearance
      mask |= 0x2   if flags.get(:face_coord)
      mask |= 0x20  if flags.get(:hit)
      mask |= 0x200 if flags.get(:hit2)
      
      # Check for overflow
      if mask >= 0x100
        mask |= 0x40
        block.add_byte mask.ubyte
        block.add_byte (mask >> 8).byte
      else
        block.add_byte mask
      end
      
      append_forced_move(p, block) if flags.get(:forced_move)
      append_graphics(p, block) if flags.get(:graphics)
      append_animation(p, block) if flags.get(:animation)
      append_forced_chat(p, block) if flags.get(:forced_chat)
      append_chat(p, block) if flags.get(:chat) && !no_chat
      append_face_entity(p, block) if flags.get(:face_entity)
      append_appearance(p, block) if flags.get(:appearance) || force_appearance
      append_face_coord(p, block) if flags.get(:face_coord)
      append_hit(p, block) if flags.get(:hit)
      append_hit2(p, block) if flags.get(:hit2)
      
      # Build packet from update block and cache it
      block_packet = block.to_packet
      
      if p != @player && !force_appearance && !no_chat
        p.cached_update = block_packet
      end
      
      packet.add_bytes block_packet.buffer
    end
    
    def update_this_player_movement(packet)
      if @player.teleporting || @player.region_change
        packet.add_bits 1, 1
        packet.add_bits 2, 3
        packet.add_bits 2, @player.location.z
        packet.add_bits 1, (@player.teleporting ? 1 : 0)
        packet.add_bits 1, (@player.flags.update_required? ? 1 : 0)
        packet.add_bits 7, @player.location.get_local_y(@player.last_location)
        packet.add_bits 7, @player.location.get_local_x(@player.last_location)
      else
        if @player.sprites[0] == -1
          if @player.flags.update_required?
            packet.add_bits 1, 1
            packet.add_bits 2, 0
          else
            packet.add_bits 1, 0
          end
        elsif @player.sprites[1] == -1
          packet.add_bits 1, 1
          packet.add_bits 2, 1
          packet.add_bits 3, @player.sprites[0]
          packet.add_bits 1, (@player.flags.update_required? ? 1 : 0)
        else
          packet.add_bits 1, 1
          packet.add_bits 2, 2
          packet.add_bits 3, @player.sprites[0]
          packet.add_bits 3, @player.sprites[1]
          packet.add_bits 1, (@player.flags.update_required? ? 1 : 0)
        end
      end
    end
  end
end
