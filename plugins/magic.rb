# Just missing level checks for things. Otherwise working.
# Could use some clean-up
# Basically the same code except for: # of fire runes, XP, item cost, anim, and graphic

# Low alch
on_magic_on_item(1162){|player, id, slot|
  fire_staff = [1387, 3053, 3055].any? {|item| player.equipment.contains(item)}
  
  if (fire_staff || player.inventory.count(554) >= 3) && player.inventory.contains(561)
    if id == 995
      player.io.send_message "You cannot turn gold into gold!"
      next
    end
    
    item = Calyx::Item::Item.new(id, 1)
    
    player.inventory.remove(-1, Calyx::Item::Item.new(554, 3)) unless fire_staff
    player.inventory.remove(-1, Calyx::Item::Item.new(561, 1))
    player.inventory.remove(slot, item)
    player.inventory.add(Calyx::Item::Item.new(995, item.definition.lowalc))
    player.skills.add_exp(:magic, 31)
    player.play_animation Calyx::World::Animation.new(712)
    player.play_graphic Calyx::World::Graphic.new(112, 2)
  else
    player.io.send_message "You do not have the required runes to cast this spell."
  end
}

# High alch
on_magic_on_item(1178){|player, id, slot|
  fire_staff = [1387, 3053, 3055].any? {|item| player.equipment.contains(item)}
  
  if (fire_staff || player.inventory.count(554) >= 5) && player.inventory.contains(561)
    if id == 995
      player.io.send_message "You cannot turn gold into gold!"
      next
    end
    
    item = Calyx::Item::Item.new(id, 1)
    
    player.inventory.remove(-1, Calyx::Item::Item.new(554, 5)) unless fire_staff
    player.inventory.remove(-1, Calyx::Item::Item.new(561, 1))
    player.inventory.remove(slot, item)
    player.inventory.add(Calyx::Item::Item.new(995, item.definition.highalc))
    player.skills.add_exp(:magic, 65)
    player.play_animation Calyx::World::Animation.new(713)
    player.play_graphic Calyx::World::Graphic.new(113, 2)
  else
    player.io.send_message "You do not have the required runes to cast this spell."
  end
}
