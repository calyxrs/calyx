module Calyx::PM
  class Presence
  
    @@last_message_index = 0
    
    def initialize(player)
      @player = player
      
      # Update friends list status
      send_friend_server 2
      
      # Send lists
      send_friends @player.varp.friends
      send_ignores @player.varp.ignores
      
      # Show as online to other players
      registered
    end
    
    def registered
      WORLD.players.each {|player| player.var.pm.register(@player) if player && player.var.pm }
    end
    
    def unregistered
      WORLD.players.each {|player| player.var.pm.unregister(@player) if player && player.var.pm }
    end
    
    def register(player)
      name = player.name_long
      send_friend(name) if @player.varp.friends.include?(name)
    end
    
    def unregister(player)
      name = player.name_long
      send_friend(name, 0) if @player.varp.friends.include?(name)
    end
    
    def send_message(to, packet)
      message = packet.read_bytes(packet.buffer.size)
      player = WORLD.players.find {|p| p && p.name_long == to }
        
      if player
        bldr = Calyx::Net::PacketBuilder.new(196, :VAR)
        bldr.add_long @player.name_long
        bldr.add_int player.var.pm.last_index
        bldr.add_byte [Calyx::World::RIGHTS.index(@player.rights), 2].min
        bldr.add_bytes message
        player.connection.send_data bldr.to_packet
      end
    end
    
    def send_friend(name, world=nil)
      world ||= get_world(name)
      world += 9 unless world == 0
      @player.connection.send_data Calyx::Net::PacketBuilder.new(50).add_long(name).add_byte(world.byte).to_packet
    end
    
    def send_friends(list)
      list.each {|friend| send_friend friend }
    end
  
    def send_ignores(list)
      unless list.empty?
        bldr = Calyx::Net::PacketBuilder.new(214)
        
        list.each {|user|
          bldr.add_long user
        }
      
        @player.connection.send_data bldr.to_packet
      end
     end
     
    def send_friend_server(status)
      # 0 = Loading, 1 = Connecting, 2 = OK
      @player.connection.send_data Calyx::Net::PacketBuilder.new(221).add_byte(status).to_packet
    end
    
    def get_world(friend)
      WORLD.players.find {|p| p && p.name_long == friend } ? 1 : 0
    end
    
    def last_index
      @@last_message_index += 1
    end
  end
end

# Login
on_player_login(:pm) {|player|
  player.varp.friends ||= []
  player.varp.ignores ||= []
  player.var.pm = Calyx::PM::Presence.new(player)
}

# Logout
on_player_logout(:pm) {|player|
  player.var.pm.unregistered
}

# Send message
on_packet(126) {|player, packet|
  player.var.pm.send_message packet.read_long, packet
}

# Add friend
on_packet(188) {|player, packet|
  name = packet.read_long
  
  if player.name_long == name
    player.io.send_message "You cannot add yourself as a friend."
    next
  end
  
  friends = player.varp.friends
  
  if friends.size >= 200
    player.io.send_message "Your friends list if full."
    next
  end
  
  if friends.include?(name)
    player.io.send_message "#{Calyx::Misc::NameUtils.long_to_name(name)} is already on your friends list."
    next
  end
  
  friends << name
  player.var.pm.send_friend name
}

# Add ignore
on_packet(133) {|player, packet|
  name = packet.read_long

  if player.name_long == name
    player.io.send_message "You cannot ignore yourself."
    next
  end
  
  ignores = player.varp.ignores

  if ignores.size >= 200
    player.io.send_message "Your ignore list if full."
    next
  end
  
  if ignores.include?(name)
    player.io.send_message "#{Calyx::Misc::NameUtils.long_to_name(name)} is already on your ignore list."
    next
  end
  
  ignores << name
}

# Remove friend
on_packet(215) {|player, packet|
  player.varp.friends.delete packet.read_long
}

# Remove ignore
on_packet(74) {|player, packet|
  player.varp.ignores.delete packet.read_long
}
