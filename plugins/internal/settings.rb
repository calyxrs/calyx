# Run settings
on_int_button(152) {|player|
  player.walking_queue.run_toggle = false
  player.settings[:move_speed] = 0
}

on_int_button(153) {|player|
  if player.settings[:energy] < 1.0
    # Not enough energy to enable
    player.walking_queue.run_toggle = false
    player.settings[:move_speed] = 0
    player.io.send_config 173, 0
  else
    player.walking_queue.run_toggle = true
    player.settings[:move_speed] = 1
  end
}

on_player_login(:move_speed) {|player|
  value = player.settings[:move_speed]
  player.walking_queue.run_toggle = value == 1
  player.io.send_config 173, (player.settings[:move_speed] || 0)
}

# Brightness
[[5451, 5452], [6157, 6273], [6274, 6275], [6276, 6277]].each_with_index {|buttons, i|
  buttons.each {|button|
    on_int_button(button) {|player|
      player.settings[:brightness] = i + 1
    }
  }
}

on_player_login(:brightness) {|player|
  player.io.send_config 166, player.settings[:brightness] || 2
}

# Mouse buttons
[6278, 6279].each_with_index {|button, i|
  on_int_button(button) {|player|
    player.settings[:mouse_buttons] = i
  }
}

on_player_login(:mouse_buttons) {|player|
  player.io.send_config 170, player.settings[:mouse_buttons] || 0
}

# Chat effects
[6280, 6281].each_with_index {|button, i|
  on_int_button(button) {|player|
    player.settings[:chat_effects] = i
  }
}

on_player_login(:chat_effects) {|player|
  player.io.send_config 171, player.settings[:chat_effects] || 0
}

[953, 952].each_with_index {|button, i|
  on_int_button(button) {|player|
    player.io.send_message "dicks #{i}"
  }
}


