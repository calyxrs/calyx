# Action buttons
on_packet(185) {|player, packet|
  button = packet.read_short
  handler = HOOKS[:int_button][button]
  
  if handler.instance_of?(Proc)
    handler.call(player)
  else
    Logging.logger['packets'].warn "Unhandled action button: #{button}"
  end
}

# Enter amount
# TODO Reset interface ID at end
on_packet(208) {|player, packet|
  amount = packet.read_int
  
  if player.interface_state.enter_amount_open?
    enter_amount_slot = player.interface_state.enter_amount_slot
    enter_amount_id = player.interface_state.enter_amount_id
    
    handler = HOOKS[:int_enteramount][player.interface_state.enter_amount_interface]
    
    if handler.instance_of?(Proc)
      handler.call(player, enter_amount_id, enter_amount_slot, amount)
    end
  end
}

# Close interface
on_packet(130) {|player, packet|
  handler = HOOKS[:int_close][player.interface_state.current_interface]
  
  if handler.instance_of?(Proc)
    handler.call(player)
  else 
    player.interface_state.interface_closed
  end
}
