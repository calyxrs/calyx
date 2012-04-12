# Idle logout
on_packet(202) {|player, packet|
  player.io.send_logout unless player.rights == :admin
}

# Enter new region
on_packet(210) {|player, packet|
  # Update objects
  WORLD.object_manager.objects.each {|object|
    if object.location.within_distance?(player.location)
      object.change(player)
    end
  }
  
  # Update NPC faces
  WORLD.region_manager.get_local_npcs(player).each {|npc|
    if npc.direction != nil
      npc.flags.flag :face_coord
    end
  }
  
  # Spawn local world items
  Calyx::World::ItemSpawns.items.each {|item|
    if !item.picked_up && item.within_distance?(player)
      item.spawn(player)
    end
  }
}

# Player option 1 (Attack)
on_packet(128) {|player, packet|
  id = packet.read_short.ushort
  raise "invalid player index: #{id}" unless (0...2000) === id
  
  victim = WORLD.players[id-1]
  if victim != nil && player.location.within_interaction_distance?(victim.location)
    player.action_queue << AttackAction.new(player, victim)
  end
}

# Player option 2 (Follow)
on_packet(73) {|player, packet|
  id = packet.read_short.ushort
  raise "invalid player index: #{id}" unless (0...2000) === id
}

# Trade options
on_packet(153, 139) {|player, packet|
  handler = HOOKS[:trade_option][packet.opcode]
                
  if handler.instance_of?(Proc)
    handler.call(player, packet)
  else
    raise "unhandled trade option opcode"
  end
}

# Character design
on_packet(101) {|player, packet|
  gender = packet.read_byte
  head = packet.read_byte
  beard = packet.read_byte
  torso = packet.read_byte
  arms = packet.read_byte
  hands = packet.read_byte
  legs = packet.read_byte
  feet = packet.read_byte
  hair_col = packet.read_byte
  torso_col = packet.read_byte
  leg_col = packet.read_byte
  feet_col = packet.read_byte
  skin_col = packet.read_byte
  
  look = [gender, hair_col, torso_col, leg_col, feet_col,
    skin_col, head, torso, arms, hands, legs, feet, beard
  ]
  
  player.appearance.set_look look
  player.interface_state.interface_closed
  player.flags.set :appearance, true
}
