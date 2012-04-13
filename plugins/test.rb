
# Logout
on_int_button(2458) {|player|
  player.io.send_logout
}

on_command("objspawn") {|player, params|
 temp_loc = player.location
  
 object = Calyx::Objects::Object.new(params[0].to_i, temp_loc, 2, params[1].to_i, -1, temp_loc, 0, params[2].to_i)
 object.change 
 
 # Add this to the object manager
 WORLD.object_manager.objects << object
}

on_command("pos") {|player, params|
  player.io.send_message "You are at #{player.location.inspect}."
}

on_command("update") {|player, params|
  time = params.first.to_i
  WORLD.submit_event Calyx::Tasks::SystemUpdateEvent.new(time)
}

on_command("dc") {|player, params|
  player.connection.close_connection
}

on_command("goup") {|player, params|
  player.teleport_location = player.location.transform(0, 0, 1)  
}

on_command("godown") {|player, params|
  player.teleport_location = player.location.transform(0, 0, -1)  
}

on_command("item") {|player, params|
  id = params[0].to_i
  count = params.length == 2 ? params[1].to_i : 1
  player.inventory.add Calyx::Item::Item.new(id, count)
}

on_command("design") {|player, params|
  player.io.send_interface 3559
}

on_item_on_player(1050) {|player, used_player|
   player.io.send_message "You used 1050 on a player"
   used_player.io.send_message "someone used you" 
}

on_item_on_npc(1050, 1) {|player, npc|
   player.io.send_message "You used a santa on an npc" 
}

on_int_button(3651) {|player|
  player.io.send_clear_screen
}

on_command("reload") {|player, params|
  player.io.send_message "Reloading..." 
  SERVER.reload
}

on_command("spawn") {|player, params|
   id = params[0].to_i
   npc = Calyx::NPC::NPC.new Calyx::NPC::NPCDefinition.for_id(id)
   npc.location = player.location.transform(1, 1, 0)
   
   WORLD.register_npc npc
}

on_command("cfg") {|player, params|
  id = params[0].to_i
  value = params[1].to_i
  player.io.send_config id, value
  player.io.send_message "Setting #{id} to #{value}"
}

on_npc_option2(592) {|player, npc|
  player.io.send_message "Open shop"
}

on_command("teleto") {|player, params|
  target = get_player(params[0])
  unless target == nil
    player.teleport_location = target.location
    player.io.send_message "You were teleported to #{target.name}."
    target.io.send_message "#{player.name} teleported to you."
  else
    player.io.send_message "User not found."
  end
}

# Have the player enter a number, and see if
# it is correct.
on_command("guess") {|player, params|
  # Turn the string into an integer using to_i
  number = params[0].to_i

  if number == 1234
    player.io.send_message "Yay! You win!"
  else
    player.io.send_message "You guessed wrong!"
  end
}

on_command("tele") {|player, params|
  x = params[0].to_i
  y = params[1].to_i
  z = params.length > 2 ? params[2].to_i : 0
  loc = Calyx::Model::Location.new(x, y, z)
  player.io.send_message "Teleporting to #{loc.inspect}..."
  player.teleport_location = loc
}

on_command("snow") {|player, params|
  player.io.send_interface(11877, true)
}

on_command("teletome") {|player, params|
  target = get_player(params[0])
  unless target == nil
    target.teleport_location = player.location
    player.io.send_message "#{target.name} was teleported to you."
    target.io.send_message "You were teleported to #{player.name}."
  else
    player.io.send_message "User not found."
  end
}

on_command("teleall") {|player, params|
  WORLD.players.each {|target|
    if target != nil and target.name != player.name
      target.teleport_location = player.location
      target.io.send_message "You were teleported to #{player.name}."
    end
  }
}

on_command("move") {|player, params|
  player.flags.flag :forced_move
}

on_command("em") {|player, params|
  val = eval("player.#{params.first}")
  player.io.send_message "returned: #{val.inspect}"
}

on_command("g") {|player, params|
  x = player.location.x + 1
  y = player.location.y
  z = player.location.z
  
  player.face Calyx::Model::Location.new(x, y, z)
}

on_command("max") {|player, params|
  Calyx::Player::Skills::SKILLS.each {|skill|
    player.skills.set_skill skill, 99, 13034431
  }
  player.flags.flag :appearance
}

on_command("md") {|player, params|
  player.model = params.first.to_i
  player.flags.flag :appearance
}

on_command("sa") {|player, params|
  player.standanim = params.first.to_i
  player.flags.flag :appearance
}

on_command("wa") {|player, params|
  player.walkanim = params.first.to_i
  player.flags.flag :appearance
}

on_command("empty") {|player, params|
  player.inventory.clear
  player.inventory.fire_items_changed
}

on_item_on_obj(1050, 1278) {|player, loc|
  player.io.send_message "Holy shit batman."
}

def self.get_player(name)
  WORLD.players.find {|e| e.name.downcase == name.downcase }
end

@@emotes = {
  161 => 860,
  162 => 857,
  163 => 863,
  164 => 858,
  165 => 859,
  166 => 866,
  167 => 864,
  168 => 855,
  169 => 856,
  170 => 861,
  171 => 862,
  172 => 865,
  13362 => 2105,
  13363 => 2106,
  13364 => 2107,
  13365 => 2108,
  13366 => 2109,
  13367 => 2110,
  13368 => 2111,
  13383 => 2127,
  13384 => 2128,
  13369 => 2112,
  13370 => 2113,
  11100 => 1368,
  667 => 1131,
  6503 => 1130,
  6506 => 1129,
  666 => 1128,
}

@@emotes.each {|button, anim|
  on_int_button(button) {|player|
    player.play_animation Calyx::Model::Animation.new(anim)
  }
}
