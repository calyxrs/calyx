module Calyx::Tasks
  class NPCTickTask
    attr :npc
    
    def initialize(npc)
      @npc = npc
    end
    
    def execute
      if @npc.region_change
        @npc.last_location = @npc.location
      end
      
      @npc.walking_queue.next_movement
    end 
  end

  class NPCResetTask
    attr :npc
    
    def initialize(npc)
      @npc = npc
    end
    
    def execute
      @npc.flags.reset
      @npc.teleporting = false
      @npc.region_change = false
      @npc.teleport_location = nil
      @npc.animation = nil
      @npc.graphic = nil
    end  
  end

  class NPCUpdateTask
    attr :player
    
    def initialize(player)
      @player = player
    end
    
    def execute
      # Update block.
      update_block = Calyx::Net::PacketBuilder.new
      packet = Calyx::Net::PacketBuilder.new(65, :VARSH)
      packet.start_bit_access
      
      # Current size of the npc list.
      packet.add_bits 8, @player.local_npcs.size
      
      # Go through every local NPC.
      @player.local_npcs.delete_if {|npc|
        should_remove = !WORLD.npcs.include?(npc) || npc.teleporting || !npc.location.within_distance?(@player.location)
        
        if should_remove
          packet.add_bits 1, 1
          packet.add_bits 2, 3
        else
          update_npc_movement packet, npc
          
          if npc.flags.update_required?
            update_npc update_block, npc
          end
        end
        
        should_remove
      }
      
      # Go through every NPC in the world.
      WORLD.region_manager.get_local_npcs(@player).each {|npc|
        # Make sure we have space and avoid duplicates.
        break if @player.local_npcs.size >= 255
        next if @player.local_npcs.include?(npc)
        
        # Add NPC to local NPCs.
        @player.local_npcs << npc
        
        # Add NPC into packet.
        add_new_npc packet, npc
        
        # Only update if there is an update needed.
        if npc.flags.update_required?
          update_npc update_block, npc
        end
      }
      
      unless update_block.empty?
        packet.add_bits 14, 16383
        packet.finish_bit_access
        packet.add_bytes(update_block.to_packet.buffer)
      else
        packet.finish_bit_access
      end
      
      @player.connection.send_data packet.to_packet
    end
    
    def add_new_npc(packet, npc)
      # Add NPC's index.
      packet.add_bits 14, npc.index
      
      # Offsets from player.
      packet.add_bits(5, npc.location.y - @player.location.y)
      packet.add_bits(5, npc.location.x - @player.location.x)
      
      # Unsure. Discard walk queue on client?
      packet.add_bits 1, 0
      
      # NPC type and whether update is required or not.
      packet.add_bits 12, npc.definition.id
      packet.add_bits(1 , npc.flags.update_required? ? 1 : 0)
    end
    
    def update_npc_movement(packet, npc)
      sprites = npc.sprites
      
      if sprites[0] == -1
        if npc.flags.update_required?
          packet.add_bits 1, 1
          packet.add_bits 2, 0
        else
          packet.add_bits 1, 0
        end
      elsif sprites[1] == -1
        packet.add_bits 1, 1
        packet.add_bits 2, 1
        packet.add_bits 3, sprites[0]
        packet.add_bits 1, (npc.flags.update_required? ? 1 : 0)
      else
        packet.add_bits 1, 1
        packet.add_bits 2, 2
        packet.add_bits 3, sprites[0]
        packet.add_bits 3, sprites[1]
        packet.add_bits 1, (npc.flags.update_required? ? 1 : 0)
      end
    end
    
    def update_npc(packet, npc)
      mask = 0
      flags = npc.flags
      
      # Calculate bitmask.
      mask |= 0x10 if flags.get(:animation)
#      mask |= 0x8 if flags.get(:hit)
      mask |= 0x80 if flags.get(:graphics)
      mask |= 0x20 if flags.get(:face_entity)
#      mask |= 0x1 if flags.get(:forced_chat)
#      mask |= 0x40 if flags.get(:hit_2)
#      mask |= 0x2 if flags.get(:transform)
      mask |= 0x4 if flags.get(:face_coord)
      
      packet.add_byte mask
      
      # Write the mask.
      update_animation(npc, packet) if flags.get(:animation)
#      update_hit(npc, packet) if flags.get(:hit)
      update_graphics(npc, packet) if flags.get(:graphics)
      update_face_entity(npc, packet) if flags.get(:face_entity)
#      update_forced_chat(npc, packet) if flags.get(:forced_chat)
#      update_hit_2(npc, packet) if flags.get(:hit_2)
#      update_transform(npc, packet) if flags.get(:transform)
      update_face_coord(npc, packet) if flags.get(:face_coord)
    end
    
    def update_animation(npc, packet)
      packet.add_leshort npc.animation.id
      packet.add_byte npc.animation.delay
    end
    
    def update_hit(npc, packet)
      # TODO
    end
    
    def update_graphics(npc, packet)
      packet.add_short npc.graphic.id
      packet.add_int npc.graphic.delay
    end
    
    def update_face_entity(npc, packet)
      packet.add_short npc.interacting_entity == nil ? -1 : npc.interacting_entity.clientindex
    end
    
    def update_forced_chat(npc, packet)
      # TODO
    end
    
    def update_hit_2(npc, packet)
      # TODO
    end
    
    def update_transform(npc, packet)
      # TODO
    end
    
    def update_face_coord(npc, packet)
      x = npc.facing == nil ? 0 : (npc.facing.x * 2 + 1)
      y = npc.facing == nil ? 0 : (npc.facing.y * 2 + 1)

      packet.add_leshort x
      packet.add_leshort y
    end
  end
end
