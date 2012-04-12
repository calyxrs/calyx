require 'xmlsimple'

module Calyx::Shops
  class ShopManager
    @@shops = {}
      
    def load_shops
      data = XmlSimple.xml_in("data/shops.xml")
      data["shop"].each {|row|
        @@shops[row['id'].to_i] = shop = Shop.new
        shop.name = row['name']
        shop.generalstore = row['generalstore'].eql?("true")  # buy modifier
        shop.customstock = row['customstock'].eql?("true")    # sell modifier
        stock = {}
        
        row['item'].each {|item|
          items = item.inject({}) {|result, (key, value)| result[key] = value.to_i; result }
          stock.store *items.values
        }
        
        shop.original_stock = stock
      }
    end
    
    def ShopManager.get(id)
      @@shops[id]
    end
    
    def ShopManager.open(shop_id, player)
      shop = @@shops[shop_id]
      return if shop == nil
    
      player.current_shop = shop
      
      shop.container.remove_empty_slots
      player.io.send_string 3901, shop.name
      player.io.send_interface_inventory 3824, 3822
      player.interface_state.add_listener shop.container, Calyx::Item::InterfaceContainerListener.new(player, 3900)
      player.interface_state.add_listener player.inventory, Calyx::Item::InterfaceContainerListener.new(player, 3823)
    end
    
    def ShopManager.clamp(x, min, max)
      x = max if x > max
      x = min if x < min
      x
    end
    
    def ShopManager.sell_value(player, slot)
      return nil if (shop = player.current_shop) == nil
      
      # Get price of the item or its parent if noted
      item = player.inventory.items[slot]
      price = item.definition.properties[:noted] ? Calyx::Item::ItemDefinition.for_id(item.definition.parent).basevalue : item.definition.basevalue
      
      # Specialty shops will pay more for items
      multiplier = shop.generalstore ? 0.4 : 0.6
      
      # Calculate what the shop is willing to pay based on supply
      current = shop.container.count(item.id)
      max = shop.original_stock[item.id] || 1
      offer = clamp(multiplier * price * (1.0 - (current / (2.0 * max))), multiplier/2 * price, multiplier * price).floor
      offer
    end
      
    def ShopManager.buy_value(player, slot)
      return nil if (shop = player.current_shop) == nil
      
      item = shop.container.items[slot]
      price = item.definition.basevalue
      
      if shop.generalstore && shop.original_stock[item.id]
        current = shop.container.count(item.id)
        max = shop.original_stock[item.id]
        price = clamp(price * (1.3 - (0.3 * current) / max), price, 1.3 * price).floor
      end
      
      price
    end
    
    def ShopManager.buy(player, slot, id, amount)
      return if (shop = player.current_shop) == nil
      return if (item = shop.container.items[slot]) == nil || item.id != id
      
      # Check if there is remaining stock
      if item.count <= 0
        player.io.send_message "The shop is currently out of stock."
        return
      end
      
      # If there are less items in shop then the player is buying, only buy what the shop has
      amount = item.count < amount ? item.count : amount
     
      new_item = Calyx::Item::Item.new id, amount
      
      # Only able to buy what fits in inventory.
      if !player.inventory.has_room_for new_item
        amount = player.inventory.free_slots
        
        if amount <= 0
          player.io.send_message "You don't have enough room in your inventory."
          return
        else
          new_item = Calyx::Item::Item.new id, amount
        end
      end
      
      price = buy_value(player, slot)
      money = player.inventory.item_for_id 995

      if money == nil || money.count < price
        player.io.send_message "You don't have enough money to buy that!"
        return
      else
        # Least amount they can buy with there money
        amount = [amount, (money.count / price).floor].min
        new_item = Calyx::Item::Item.new id, amount
      end
      
      total = price * amount
      left_over = item.count - amount
      
      # Make sure player has enough to even purchase the item(s).
      if money.count >= total
        # Make sure the player has enough space in their inventory.
        if player.inventory.has_room_for new_item
          # Remove money from inventory, if no more money empty slot entirely.
          new_money = (money.count - total) > 0 ? Calyx::Item::Item.new(995, money.count - total) : nil
          player.inventory.set player.inventory.slot_for_id(995), new_money
          
          # Add the purchased item(s) to the player's inventory.
          player.inventory.add new_item
          
          # Remove the purchased item(s) from the shop's stock.
          if (item.count - amount) <= 0 && shop.original_stock.include?(item.id)
            shop.container.set slot, Calyx::Item::Item.new(id, 0)
          elsif (item.count - amount) > 0
            shop.container.set slot, Calyx::Item::Item.new(id, left_over)
          else
            shop.container.set slot, nil
          end
        else
          player.io.send_message "You don't have enough room in your inventory."
        end
      else
        player.io.send_message "You don't have enough money to buy that!"
      end
    end
    
    def ShopManager.sell(player, slot, id, amount)
      return if (shop = player.current_shop) == nil
      return if (item = player.inventory.items[slot]) == nil || item.id != id
    
      # If shop doesn't have custom stock and it's not in the original stock 
      if !shop.customstock && !shop.original_stock.include?(id)
        player.io.send_message "You cannot sell #{item.definition.name} in this store."
        return
      end
      
      # Only sell what the player has
      if item.definition.properties[:stackable]
        amount = (item.count - amount) > 0 ? amount : item.count
      else
        amount = player.inventory.count(item.id) < amount ? player.inventory.count(item.id) : amount
      end
      
      # Un-note if noted
      if item.definition.properties[:noted]
        shop_item = Calyx::Item::Item.new(item.definition.parent, amount)
      else
        shop_item = Calyx::Item::Item.new item.id, amount
      end
      
      # Only sell if shop has room for it
      if !shop.container.has_room_for shop_item
        player.io.send_message "The shop is currently full."
        return
      end
      
      price = (sell_value(player, slot) * amount).to_i
      if price <= 0
        player.io.send_message "You cannot sell #{item.definition.name} in this store."
        return
      end
      
      money = Calyx::Item::Item.new 995, price
      
      if player.inventory.has_room_for money
        player.inventory.remove slot, Calyx::Item::Item.new(item.id, amount)
        
        # Add item to shop
        shop.container.add shop_item
        
        money_slot = player.inventory.slot_for_id(995)
        
        # If player already has money.
        if money_slot != -1
          new_money = Calyx::Item::Item.new 995, (player.inventory.items[money_slot].count + price)
          player.inventory.set money_slot, new_money
        else
          new_money = Calyx::Item::Item.new 995, price
          player.inventory.add new_money
        end
      else
        player.io.send_message "You don't have enough room in your inventory."
      end
    end
  end
    
  class Shop
    attr :container
    attr_accessor :name
    attr_accessor :generalstore
    attr_accessor :customstock
    attr_accessor :original_stock
        
    def initialize
      @container = Calyx::Item::Container.new true, 40
    end
    
    def original_stock=(stock)
      @container.clear
      @original_stock = stock
      @original_stock.each {|item, amount|
        @container.items << Calyx::Item::Item.new(item, amount)
      }
    end
  end
end
