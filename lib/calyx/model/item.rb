module Calyx::Item
  class Item
    attr :id
    attr :count
    
    def initialize(id, count = 1)
      @id = id
      @count = count
    end
    
    def definition
      ItemDefinition.for_id @id
    end
    
    def inspect
      "[id=#{@id}, count=#{@count}]"
    end
  end
  
  class ItemDefinition
    # prices, basevalue
    PROPERTIES = [:name, :noted, :parent, :noteable, :noteID, :stackable, :members, :prices, :basevalue, :att_stab_bonus,
                  :att_slash_bonus, :att_crush_bonus, :att_magic_bonus, :att_ranged_bonus, :def_stab_bonus, :def_slash_bonus,
                  :def_crush_bonus, :def_magic_bonus, :def_ranged_bonus, :strength_bonus, :prayer_bonus, :weight]
    BOOL_PROPERTIES = [:noted, :noteable, :stackable, :members, :prices]
    
    @@db = nil
    @@definitions = {}
    
    attr :id
    attr_reader :properties
    
    def initialize(id)
      @id = id
      @properties = lambda do |key|
        if PROPERTIES.include?(key)
          val = @@db.get_first_value("select #{key} from items where id = #{@id}")
          BOOL_PROPERTIES.include?(key) ? val == 1 : val
        else
          nil
        end
      end
    end
    
    PROPERTIES.each do |p|
      define_method(p.id2name) do
        @properties[p]
      end
    end
    
    def highalc
      (0.6 * basevalue).to_i
    end
    
    def lowalc
      (0.4 * basevalue).to_i
    end
    
    def ItemDefinition.for_id(id)
      if @@definitions[id] == nil
        @@definitions[id] = ItemDefinition.new(id)
      end
      
      @@definitions[id]
    end
    
    def ItemDefinition.load
      @@db = SQLite3::Database.new('./data/items.db', :readonly => true)
    end
  end
  
  # Container changed
  class ContainerListener
    def slot_changed(container, slot)
      raise "Slots change is abstract"
    end
    
    def slots_changed(container, slots)
      raise "Slots changed is abstract"
    end
    
    def items_changed(container)
      raise "Items changed is abstract"
    end
  end
  
  class InterfaceContainerListener < ContainerListener
    attr :player
    attr :interface_id
    
    def initialize(player, interface_id)
      @player = player
      @interface_id = interface_id
    end
    
    def slot_changed(container, slot)
      @player.io.send_update_item(@interface_id, slot, container.items[slot])
    end
    
    def slots_changed(container, slots)
      @player.io.send_update_some_items(@interface_id, slots, container.items)
    end
    
    def items_changed(container)
      @player.io.send_update_items(@interface_id, container.items)
    end
  end
  
  class WeightListener < ContainerListener
    attr :player
    
    def initialize(player)
      @player = player
    end
    
    def slot_changed(container, slot)
      update_weight
    end
    
    def slots_changed(container, slots)
      update_weight
    end
    
    def items_changed(container)
      update_weight
    end
    
    private
    
    def update_weight
      weight = calculate_weight
      @player.connection.send_data Calyx::Net::PacketBuilder.new(240).add_short(weight.to_i).to_packet
    end
    
    def calculate_weight
      weight = 0.0
      weight += @player.inventory.items.inject(0) {|sum, item| sum + (item ? item.definition.weight : 0) }
      weight += @player.equipment.items.inject(0) {|sum, item| sum + (item ? item.definition.weight : 0) }
      weight
    end
  end
  
  class BonusListener < ContainerListener
    attr :player
    attr :bonus_names
    
    def initialize(player)
      @player = player
      @bonus_names = ['Stab', 'Slash', 'Crush', 'Magic', 'Range', 
        'Stab', 'Slash', 'Crush', 'Magic', 'Range',
        'Strength', 'Prayer']
    end
    
    def slot_changed(container, slot)
      update_bonuses
    end
    
    def slots_changed(container, slots)
      update_bonuses
    end
    
    def items_changed(container)
      update_bonuses
    end
    
    def equipment_bonus(id)
      bonus = case id
      when Symbol
        id
      when Integer
        Calyx::Item::ItemDefinition::PROPERTIES[id + 9]
      end
      
      if bonus
        player.equipment.items.inject(0) {|sum, item| sum + (item ? item.definition.send(bonus) : 0) }
      else
        nil
      end
    end
        
    private
    
    def update_bonuses
      offset = 0
      for i in 0...12
        bonus = equipment_bonus(i)
        offset = 1 if i == 10
        sign = bonus >= 0 ? "+" : "-"
        @player.io.send_string 1675 + i + offset, "#{bonus_names[i]}: #{sign}#{bonus}"
      end
    end
  end

  class Container
    MAX_ITEMS = 2**31-1
    attr :capacity
    attr :items
    attr :listeners
    attr :always_stack
    attr_accessor :fire_events
          
    def initialize(always_stack, capacity)
      @capacity = capacity
      @items = Array.new(@capacity, nil)
      @listeners = []
      @always_stack = always_stack
      @fire_events = true
    end
    
    def add(item)
      if item.definition.properties[:stackable] or @always_stack
        new = @items.find {|e| e && e.id == item.id }
        i = @items.index(new)
        existing = new != nil
        
        if existing
          count = item.count + new.count
          return false if count > MAX_ITEMS || count < 1
          
          set i, Item.new(new.id, count)
          return true
        else
          slot = get_free_slot
          set slot, item if slot != -1
          return slot != -1
        end
      else
        slots = free_slots
        return false unless slots >= item.count
        
          fire = @fire_events
          @fire_events = false
        begin
          item.count.times {
            set get_free_slot, Item.new(item.id) 
          }
          fire_items_changed if fire
          return true
        ensure
          @fire_events = fire
        end
      end
      
      return false
    end
    
    def insert(from_slot, to_slot)
      if @items[to_slot] == nil
        swap from_slot, to_slot
      else
		    while from_slot != to_slot
		      if from_slot > to_slot
		        swap from_slot, from_slot - 1, true
		        from_slot -= 1
		      elsif from_slot < to_slot
		        swap from_slot, from_slot + 1, true
		        from_slot += 1
		      end
		    end
		  end
		  
		  fire_items_changed if @fire_events
	  end

    def set(index, item)
      @items[index] = item
      fire_slot_changed index if @fire_events
    end
    
    def remove(preferred, item)
      removed = 0
      
      if item.definition.properties[:stackable] or @always_stack
        slot = slot_for_id item.id
        stack = @items[slot]
        
        if stack.count > item.count
          removed = item.count
          set slot, Item.new(stack.id, stack.count - item.count)
        else
          removed = stack.count
          set slot, nil
        end
      else
        item.count.times {|i|
          slot = slot_for_id item.id
          
          if i == 0 && preferred != -1
            in_slot = @items[preferred]
            slot = preferred if in_slot.id == item.id
          end
          
          if slot != -1
            removed += 1
            set slot, nil
          else
            break
          end
        }
      end
      
      return removed
    end
    
    def Container.transfer(from, to, slot, id)
      item = from.items[slot]
      return false if item == nil or item.id != id
      
      success = to.add item
      from.set slot, nil if success
      success
    end
    
    def swap(from, to, stfu = false)
      @items[from], @items[to] = @items[to], @items[from]
      slots = [from, to]
      fire_slots_changed(slots) if @fire_events && !stfu
    end
    
    def count(id)
      @items.inject(0) {|sum, v| v != nil && v.id == id ? sum + v.count : sum }
    end
    
    def item_for_id(id)
      @items.find {|e| e && e.id == id }
    end
    
    def slot_for_id(id)
      @items.index {|e| e && e.id == id } or -1
    end
    
    def contains(id)
      slot_for_id(id) != -1
    end
    
    def add_listener(listener)
      @listeners << listener
      listener.items_changed self
    end
    
    def remove_empty_slots
      kept = @items.reject {|e| e == nil }
      @items = kept + ([nil] * (@capacity-kept.size))
      fire_items_changed if @fire_events
    end
    
    def get_free_slot
      @items.index nil or -1
    end
    
    def has_room_for(item)
      if ItemDefinition.for_id(item.id).properties[:stackable] or @always_stack
        new = @items.find {|e| e && e.id == item.id }
        existing = new != nil
        
        if existing
          count = item.count + new.count
          return false if count > MAX_ITEMS or count < 1
          return true
        end
        get_free_slot != -1
      else
        free_slots >= item.count
      end
    end
    
    def is_slot_used(slot)
      @items[slot] != nil 
    end
    
    def is_slot_free(slot)
      @items[slot] == nil
    end
    
    def size
      @items.count {|i| i != nil }
    end
    
    def clear
      @items = Array.new(@capacity, nil)
      fire_items_changed if @fire_events
    end  
    
    def free_slots
      @capacity-size
    end
    
    def fire_slot_changed(slot)
      @listeners.each {|e|
        e.slot_changed self, slot 
      }
    end
    
    def fire_slots_changed(slots)
      @listeners.each {|e|
        e.slots_changed self, slots 
      }
    end
    
    def fire_items_changed
      @listeners.each {|e|
        e.items_changed self 
      }
    end
  end
end
