# Interface container sizes
set_int_size(3214, 28)

# Item swap
on_item_swap(3214) {|player, from_slot, to_slot|
  player.inventory.swap from_slot, to_slot
}

# Listener
on_player_login(:inventory) {|player|
  player.inventory.add_listener Calyx::Item::InterfaceContainerListener.new(player, 3214)
  player.inventory.add_listener Calyx::Item::WeightListener.new(player)
}

