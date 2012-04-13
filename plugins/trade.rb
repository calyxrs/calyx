# Interface container sizes
set_int_size(3322, 28)
set_int_size(3415, 28)

# Trade window buttons
on_int_button(3651) {|player|
  case player.interface_state.current_interface
    when 3323, 3443
      Trade.close player
    else
      player.io.send_clear_screen
      player.interface_state.interface_closed
  end
}

on_int_button(3420) {|player|
  Trade.accept player
}

on_int_button(3546) {|player|
  Trade.accept player
}

# Item offer/remove amount 1
on_item_option(3322) {|player, id, slot|
  Trade.offer_item player, slot, id, 1
}
 
on_item_option(3415) {|player, id, slot|
  Trade.remove_item player, slot, id, 1
}

# Item offer/remove amount 5
on_item_option2(3322) {|player, id, slot|
  Trade.offer_item player, slot, id, 5
}
 
on_item_option2(3415) {|player, id, slot|
  Trade.remove_item player, slot, id, 5
}

# Item offer/remove amount 10
on_item_option3(3322) {|player, id, slot|
  Trade.offer_item player, slot, id, 10
}
 
on_item_option3(3415) {|player, id, slot|
  Trade.remove_item player, slot, id, 10
}

# Item offer/remove amount all
on_item_option4(3322) {|player, id, slot|
  Trade.offer_item player, slot, id, player.inventory.count(id)
}
 
on_item_option4(3415) {|player, id, slot|
  Trade.remove_item player, slot, id, player.offered_items.count(id)
}

# Item offer/remove amount x
on_int_enter_amount(3322) {|player, id, slot, amount|
  Trade.offer_item player, slot, id, amount
}

on_int_enter_amount(3415) {|player, id, slot, amount|
  Trade.remove_item player, slot, id, amount
}

on_int_close(3323) {|player|
  Trade.close player 
}

on_int_close(3443) {|player|
  Trade.close player 
}

on_player_trade(153) {|player, packet|
  Trade.request player, packet
}

on_player_trade(139) {|player, packet|
  Trade.accepted_request player, packet
}

# Close trade on logout
on_player_logout(:cancel_trade) {|player, packet|
  Trade.close player
}

class Trade
  def self.request(player, packet)
    targetSlot = packet.read_byte
    target = WORLD.players[targetSlot-1]
               
    return unless player.location.within_interaction_distance?(target.location)
    
    if target.request_manager.request_state != :participating
      # Already an open request
      if target.request_manager.acquaintance == player && target.request_manager.request_state = :requested
        open player, target
        player.request_manager.request_state = :participating
        target.request_manager.request_state = :participating
      else
        player.io.send_message "Sending trade request..."
        player.request_manager.request_state = :requested
        player.request_manager.acquaintance = target
        target.request_manager.request_state = :requested
        target.io.send_message "#{player.name}:tradereq:"
      end
    else
      player.io.send_message "Other player is busy at the moment."
    end
  end
  
  def self.accepted_request(player, packet)
    targetSlot = packet.read_byte
    target = WORLD.players[targetSlot-1]
         
    return unless player.location.within_interaction_distance?(target.location)
          
    if player.request_manager.request_state == :requested
      open player, target
      player.request_manager.request_state = :participating
      target.request_manager.request_state = :participating
    end
  end
  
  def self.open(player, target)
    player.request_manager.trade_state = :first_screen
    target.request_manager.trade_state = :first_screen
    player.request_manager.acquaintance = target
    target.request_manager.acquaintance = player
    
    start player, target
    start target, player
  end
  
  def self.start(player, target)
    # Show trade and inventory interface
    player.interface_state.interface_opened 3323
    player.io.send_interface_inventory 3323, 3321
    
    refresh player
    
    # Update text
    player.io.send_string 3417, "Trading with: #{target.name}"
      
    # Clear acceptance strings
    player.io.send_string 3431, ""
    player.io.send_string 3535, ""
  end
  
  def self.accepted_trade(player, target)
    if player == nil || target == nil
      cancel player, target
    end
    
    player.request_manager.accepted_trade = true

    case player.request_manager.trade_state
    when :first_screen
      handle_first_screen player, target
    when :second_screen
      handle_second_screen player, target
    end
  end
  
  def self.accept(player)
    target = player.request_manager.acquaintance

    accepted_trade player, target
  end
  
  def self.offer_item(player, slot, id, amount = 1)
    target = player.request_manager.acquaintance
    
    if player == nil || target == nil
      close player, target
    end
    
    item = player.inventory.items[slot]
    if item == nil
      return
    end
    
    # Make sure we only add as many as we have
    if amount > player.inventory.count(item.id)
      amount = player.inventory.count item.id
    end
    
    offeredItem = Calyx::Item::Item.new item.id, amount
    player.inventory.remove slot, offeredItem
    player.offered_items.add offeredItem
    target.gained_items.add offeredItem
    
    refresh player
    refresh target
  end
  
  def self.remove_item(player, slot, id, amount = 1)
    target = player.request_manager.acquaintance
          
    if player == nil || target == nil
      close player, target
    end
    
    item = player.offered_items.items[slot]
    if item == nil
      return
    end
    
    # Make sure we only add as many as we have
    if amount > player.offered_items.count(item.id)
      amount = player.offered_items.count item.id
    end
    
    removedItem = Calyx::Item::Item.new item.id, amount
    player.inventory.add removedItem
    player.offered_items.remove slot, removedItem
    target.gained_items.remove slot, removedItem
    
    refresh player
    refresh target
  end
  
  def self.handle_first_screen(player, target)
    accepted = player.request_manager.accepted_trade
    target_accepted = target.request_manager.accepted_trade
          
    if accepted && target_accepted
      unless player.inventory.free_slots >= player.gained_items.size
        player.io.send_message "You do not have enough space in your inventory."
        target.io.send_message "Other player does not have enough space in their inventory."
        clean player
        clean target
        return
      end
      
      unless target.inventory.free_slots >= target.gained_items.size
        target.io.send_message "You do not have enough space in your inventory."
        player.io.send_message "Other player does not have enough space in their inventory."
        clean player
        clean target
        return
      end
      
      player.request_manager.accepted_trade = false
      target.request_manager.accepted_trade = false
      player.request_manager.trade_state = :second_screen
      target.request_manager.trade_state = :second_screen
      
      open_second_screen player
      open_second_screen target
    elsif accepted && !target_accepted
      player.io.send_string 3431, "Waiting for the other player..."
      target.io.send_string 3431, "Other player has accepted"
    elsif !accepted && target_accepted
      target.io.send_string 3431, "Waiting for the other player..."
      player.io.send_string 3431, "Other player has accepted"
    else
      player.io.send_string 3431, ""
      target.io.send_string 3431, ""
    end
  end
  
  def self.handle_second_screen(player, target)
    accepted = player.request_manager.accepted_trade
    target_accepted = target.request_manager.accepted_trade
    
    if accepted && target_accepted
      exchange player, target
      player.io.send_message "Trade accepted."
      target.io.send_message "Trade accepted."
      
      player.request_manager.trade_state = :first_screen
      target.request_manager.trade_state = :first_screen
      player.request_manager.accepted_trade = false
      target.request_manager.accepted_trade = false
      
      player.io.send_clear_screen
      target.io.send_clear_screen


    elsif accepted && !target_accepted
      player.io.send_string 3535, "Waiting for the other player..."
      target.io.send_string 3535, "Other player has accepted"
    elsif !accepted && target_accepted
      target.io.send_string 3535, "Waiting for the other player..."
      player.io.send_string 3535, "Other player has accepted"
    else
      player.io.send_string 3535, ""
      target.io.send_string 3535, ""
    end
  end
  
  def self.open_second_screen(player)
    player.interface_state.interface_opened 3443
    player.io.send_interface_inventory 3443, 3213
    
    # update inventory items
    player.io.send_update_items 3214, player.inventory.items
    player.io.send_string 3557, mask_list(player.offered_items.items)
    player.io.send_string 3558, mask_list(player.gained_items.items)
  end
  
  def self.mask_list(items)
    output = "Absolutely nothing!"
    amount = ""
    count = 0
    
    items.each {|i|
      unless i == nil
        amount = case i.count
          when (1000..1000000)
            "@cya@ #{i.count / 1000} K @whi@(#{i.count})"
          when (1000000..2147483647)
            "@gre@ #{i.count / 1000000} million @whi@(#{i.count})"
          else
            "#{i.count}"
        end
        
        if count == 0
          output = Calyx::Item::ItemDefinition.for_id(i.id).name
        else
          output << "\\n#{Calyx::Item::ItemDefinition.for_id(i.id).name}"
        end
        
        if Calyx::Item::ItemDefinition.for_id(i.id).stackable
          output << " x #{amount}"
        end
        
        count = count+1
      end
    }
    
    return output
  end
  
  def self.exchange(player, target)
    if player == nil || target == nil
      cancel player, target
    end
    
    player.gained_items.items.each {|i| 
      if i != nil
        player.inventory.add i
      end
    }
    
    target.gained_items.items.each {|i| 
      if i != nil
        target.inventory.add i
      end
    }
    
    clean player
    clean target
  end
  
  def self.refresh(player)
    player.io.send_update_items 3322, player.inventory.items      # Update inventory items
    player.io.send_update_items 3415, player.offered_items.items  # Update offered items
    player.io.send_update_items 3416, player.gained_items.items   # Update target's offer
  end
  
  def self.cancel(player, target)
    # Reset player items
    if player != nil
      player.offered_items.items.each {|i| 
        if i != nil
          player.inventory.add i
        end
      }
      
      clean player
      player.io.send_message "You decline the trade."
    end
    
    # Reset target items
    if target != nil
      target.offered_items.items.each {|i| 
        if i != nil
          target.inventory.add i
        end
      }
      
      clean target
      target.io.send_message "Other player declined the trade."
    end
  end
  
  def self.clean(player)
    req = player.request_manager
    req.request_state = :normal
    req.trade_state = :none
    req.accepted_trade = false
    req.acquaintance = nil
    
    player.offered_items.clear
    player.gained_items.clear
    refresh player
  end
      
  def self.close(player)
   target = player.request_manager.acquaintance
       
   player.interface_state.interface_closed
   
   if target != nil
     target.interface_state.interface_closed
     target.io.send_clear_screen
   end
   
  cancel player, target
 end
end
