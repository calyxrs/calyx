# Mouse click
on_packet(241) {|player, packet|
  raw = packet.read_int
  time = (raw >> 20) & 4095
  button = (raw >> 19) & 1
  coords = raw & 524287
  y = coords / 765
  x = coords - (y * 765)
  HOOKS[:mouse_click].each {|k, v| v.call(player, x, y, button) }
}

# Camera
on_packet(86) {|player, packet|
  height = (packet.read_short.ushort - 128).ubyte
  rotation = (packet.read_short_a.ushort * 45) >> 8
  HOOKS[:camera_move].each {|k, v| v.call(player, rotation, height) }
}

# Quiet packet handler
QUIET ||= [
  0, 77, 78, 3, 226, 148, 36,
  246, 165, 121, 150, 238, 183,
  230, 136, 189, 152, 200, 85
]

on_packet(*QUIET)
