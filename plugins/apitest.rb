# Controls
=begin
on_mouse_click {|player, x, y, button|
  player.io.send_message "Clicked at (#{x}, #{y}) with button #{button}."
}

on_camera_move {|player, rotation, height|
  player.io.send_message "Rotation: #{rotation} degrees, height: #{height} (#{height*100/255}%)."
}

on_camera_move {|player, rotation, height|
  directions = ["north", "northwest", "west", "southwest", "south", "southeast", "east", "northeast"]
  dir = rotation / 45
  player.io.send_message "You are currently looking #{directions[dir]}."
}
=end

# Chat
on_chat {|player, effect, color, message|
  if color == 1 # red
    player.io.send_message "Your message '#{message}' was red."
  end
}

on_command("test1") {|player, params|
  player.io.send_message "Params: #{params.join(" ")}"
  player.rights = :admin
}

on_command("test2", :admin) {|player, params|
  player.io.send_message "Access granted!"
}

# Interface
on_int_button(8654) {|player|
  player.io.send_message "Honk!"
}

on_int_enter_amount(1234) {|player, amount_id, amount_slot, amount|
  # TODO proper test
}
