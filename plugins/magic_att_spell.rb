require 'xmlsimple'
require 'pp'

rune_data = XmlSimple.xml_in("data/magic_runes.xml", 'KeyToSymbol' => true)[:rune]

RUNES ||= {}

rune_data.each {|data|
  name = data["name"].to_sym
  id = data["id"].to_i
  staves = data.include?(:staff) ? data[:staff].collect {|v| v["id"].to_i } : []
  parts = data.include?(:part) ? data[:part].collect {|v| v["name"].to_sym } : []
  
  RUNES[name] = {
    :id => id,
    :staves => staves
  }
  
  RUNES[name][:parts] = parts unless parts.empty? 
}

def cast_spell(req, player)
  req.default = 0
  
  remaining = req.dup
  
  # Staffs
  req.each {|rune, amount|
    remaining[rune] -= amount if RUNES[rune][:staves].any? {|item| player.equipment.contains(item) }
  }
  
  # Combination runes
  combinations = RUNES.find_all {|k, v|
    if v.include?(:parts)
      v[:parts].each {|part|
        remaining[part] -= 1 if player.inventory.contains(RUNES[k][:id])
      }
    end
  }
  
  # Standard runes
  req.each {|rune, amount|
    remaining[rune] -= amount if player.inventory.count(RUNES[rune][:id]) >= amount
  }
  
  if remaining.any? {|k, v| v > 0 }
    player.io.send_message "You do not have the required runes to cast this spell."
  end
end

on_magic_on_npc(1152) {|player, npc|
  cast_spell({:air => 1, :mind => 1}, player)
}

def projectile(src, dest, angle, speed, id, start_z, end_z, index)
  offset = Calyx::Model::Location.new(-(src.x-dest.x), -(src.x-dest.y), 0)
  
  WORLD.region_manager.get_local_players(src).each {|p|
    if p && p.location.within_distance?(src)
      # Region
      region = Calyx::Net::PacketBuilder.new(85)
      region.add_byte_c(src.get_local_y(p.last_location) -2 )
      region.add_byte_c(src.get_local_x(p.last_location) -3)
      p.connection.send_data region.to_packet
      
      # Graphic
      graphic = Calyx::Net::PacketBuilder.new(117)
      graphic.add_byte angle
      graphic.add_byte offset.y
      graphic.add_byte offset.x
      graphic.add_short (index + 1)
      graphic.add_short id
      graphic.add_byte start_z
      graphic.add_byte end_z
      graphic.add_short 50+12
      graphic.add_short speed
      graphic.add_byte 16
      graphic.add_byte 64
      p.connection.send_data graphic.to_packet
    end
  }
end

def stillgfx(id, x, y, z)
  loc = Calyx::Model::Location.new(x, y, z)

  WORLD.region_manager.get_local_players(loc).each {|p|
    if p && p.location.within_distance?(loc)
      # Region
      region = Calyx::Net::PacketBuilder.new(85)
      region.add_byte_c loc.get_local_y(p.last_location)
      region.add_byte_c loc.get_local_x(p.last_location)
      p.connection.send_data region.to_packet

      # Graphic
      graphic = Calyx::Net::PacketBuilder.new(4)
      graphic.add_byte 0    # Tiles away = (X >> 4 + Y & 7)
      graphic.add_short id  # Graphic ID
      graphic.add_byte 80   # Height
      graphic.add_short 14  # Time before casting the graphic
      p.connection.send_data graphic.to_packet
    end
  }
end					

on_magic_on_npc(1183) {|player, npc|
  player.walking_queue.reset
  player.interacting_entity = npc
  player.walking_queue.reset
  
  player.play_graphic Calyx::Model::Graphic.new(158, 6553600)
  player.play_animation Calyx::Model::Animation.new(711)
  
  projectile(player.location, npc.location, 50, 90, 159, 40, 40, npc.index)
}
