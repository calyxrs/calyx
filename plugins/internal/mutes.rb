# Disable chat if player is muted
on_chat(:mute){|player, effect, color, message|
  if player.settings[:muted]
    :nodefault
  end
}

# Send message on login
on_player_login(:mute){|player|
  if player.settings[:muted]
    player.io.send_message "You have been muted for breaking a rule."
  end
}
