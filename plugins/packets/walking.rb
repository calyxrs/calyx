# Walking
on_packet(164, 248, 98) {|player, packet|
  # Calculate step length
  size = packet.buffer.size
  size = size-14 if packet.opcode == 248
  steps = (size-5)/2
  
  # Reset walking queue and actions
  player.walking_queue.reset
  player.action_queue.clear_non_walkable
  player.io.send_clear_screen
  player.reset_interacting_entity
  
  first_x = packet.read_leshort_a
  path = []
  
  steps.times {
    path << [packet.read_byte, packet.read_byte]
  }
  
  first_y = packet.read_leshort
  
  run_queue = packet.read_byte_c == 1 && player.settings[:energy] >= 1.0
  
  player.walking_queue.run_queue = run_queue
  
  player.walking_queue.add_step first_x, first_y
  
  path.each {|step|
    x = step[0]+first_x
    y = step[1]+first_y
    player.walking_queue.add_step x, y
  }
  
  player.walking_queue.finish
}
