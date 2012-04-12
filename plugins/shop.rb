# Interface container sizes
set_int_size(3900, 40)
set_int_size(3823, 28)

# Value of item
on_item_option(3900) {|player, id, slot|
  value = Calyx::Shops::ShopManager.buy_value(player, slot).to_i
  name = Calyx::Item::ItemDefinition.for_id(id).name
  
  if value <= 0
    player.io.send_message "You cannot buy that item."
  else
    label = ""
    label = "(#{value / 1e3.to_i}K)" if value >= 1e3.to_i && value < 1e6.to_i
    label = "(#{value / 1e6.to_i} million)" if value >= 1e6.to_i
    player.io.send_message "#{name}: currently costs #{value} coins #{label}"
  end
}

on_item_option(3823) {|player, id, slot|
  unless player.current_shop == nil
    value = Calyx::Shops::ShopManager.sell_value(player, slot).to_i
    name = Calyx::Item::ItemDefinition.for_id(id).name
    shop = player.current_shop
    
    if value <= 0 || (!shop.original_stock.include?(id) && !shop.customstock)
      player.io.send_message "You cannot sell #{name} in this store."
    else
      label = ""
      label = "(#{value / 1e3.to_i}K)" if value >= 1e3.to_i && value < 1e6.to_i
      label = "(#{value / 1e6.to_i} million)" if value >= 1e6.to_i
      player.io.send_message "#{name}: shop will buy for #{value} coins #{label}"
    end
  end
}

# Item buy/sell amount 1
on_item_option2(3823) {|player, id, slot|
  Calyx::Shops::ShopManager.sell player, slot, id, 1
}

on_item_option2(3900) {|player, id, slot|
  Calyx::Shops::ShopManager.buy player, slot, id, 1
}

# Item buy/sell amount 5
on_item_option3(3823) {|player, id, slot|
  Calyx::Shops::ShopManager.sell player, slot, id, 5
}

on_item_option3(3900) {|player, id, slot|
  Calyx::Shops::ShopManager.buy player, slot, id, 5
}

# Item buy/sell amount 10
on_item_option4(3823) {|player, id, slot|
  Calyx::Shops::ShopManager.sell player, slot, id, 10
}

on_item_option4(3900) {|player, id, slot|
  Calyx::Shops::ShopManager.buy player, slot, id, 10
}

on_int_close(3824) {|player|
  player.current_shop = nil
}

# Testing
on_command("shop") {|player, params|
  Calyx::Shops::ShopManager.open(1, player)
}