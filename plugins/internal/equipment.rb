require 'to_regexp'
require 'xmlsimple'

module Calyx::Equipment
  SIDEBARS ||= {}
  SLOTS ||= []
  EXCEPTIONS ||= []
  
  LOG ||= Logging.logger['data']

  def self.load()
    begin
      # Load sidebars
      SIDEBARS.clear
      sidebar_data = XmlSimple.xml_in("data/equipment_sidebars.xml", 'KeyToSymbol' => true)
      sidebar_data[:sidebar].each {|sidebar|
        SIDEBARS[sidebar["regex"].to_regexp] = {
          :type => sidebar["type"].to_sym,
          :id => sidebar["id"].to_i
        }
      }
      
      # Load slots
      SLOTS.clear
      slot_data = XmlSimple.xml_in("data/equipment_slots.xml", 'KeyToSymbol' => true)
      slot_data[:slot].each {|slot|
        SLOTS << {:slot => slot["id"].to_i, :check => slot["check"].to_i, :names => slot[:name]}
      }
      
      # Load exceptions
      EXCEPTIONS.clear
      exception_data = XmlSimple.xml_in("data/equipment_exceptions.xml", 'KeyToSymbol' => true)
      exception_data[:exception].each {|exception|
        EXCEPTIONS << {:id => exception["id"].to_i, :slot => exception["slot"].to_i}
      }
    rescue Exception => e
      LOG.error "Failed to load equipment data!"
      LOG.error e
    end
  end    

  def self.slot(name)
    name = name.downcase
    slot = SLOTS.find {|e| e[:names].find {|s| name.include?(s) } }
    (slot && slot[:slot]) || 3
  end

  def self.is(item, type)
    name = item.definition.name.downcase
    slot = SLOTS.find {|e| e[:check] == type }
    slot[:names].find {|s| name.include?(s) } != nil
  end

  def self.get_exception(id)
    item = EXCEPTIONS.find {|e| e[:id] == id }
    item && item[:slot]
  end

  def self.equip(player, item, slot, name, id)
    if item != nil && item.id == id
     equip_slot = self.get_exception(item.id)
     equip_slot = slot(name) if equip_slot == nil
    
     oldEquip = nil
     stackable = false
     
     if player.equipment.is_slot_used(equip_slot) && !stackable
       oldEquip = player.equipment.items[equip_slot]
       player.equipment.set equip_slot, nil
     end
     
     player.inventory.set slot, nil
     player.inventory.add oldEquip unless oldEquip == nil
     
     if stackable
       player.equipment.add item
     else
       player.equipment.set equip_slot, item
     end
   end
  end
  
  class AppearanceContainerListener < Calyx::Item::ContainerListener
    attr :player
    
    def initialize(player)
      @player = player
    end
    
    def slot_changed(container, slot)
      @player.flags.flag :appearance
    end
    
    def slots_changed(container, slots)
      @player.flags.flag :appearance
    end
    
    def items_changed(container)
      @player.flags.flag :appearance
    end
  end
  
  class SidebarContainerListener < Calyx::Item::ContainerListener
    MATERIALS ||= [
      "Iron", "Steel", "Scythe", "Black", "Mithril", "Adamant",
      "Rune", "Granite", "Dragon", "Crystal", "Bronze"
    ]
  
    attr :player
    
    def initialize(player)
      @player = player
    end
    
    def slot_changed(container, slot)
      send_weapon if slot == 3
    end
    
    def slots_changed(container, slots)
      slot = slots.find {|e| e == 3}
      send_weapon unless slot == nil
    end
    
    def items_changed(container)
      send_weapon
    end
    
    def send_weapon
      weapon = player.equipment.items[3]
      
      if weapon
        name = weapon.definition.name
        send_sidebar name, weapon.id, find_sidebar_interface(name)
      else
        # No weapon wielded
        @player.io.send_sidebar_interface 0, 5855
        @player.io.send_string 5857, "Unarmed"
      end
    end
    
    private
    
    def find_sidebar_interface(name)
      SIDEBARS.each {|matcher, data|
        formatted_name = data[:type] == :generic ? filter_name(name) : name
        
        if formatted_name =~ matcher
          return data[:id]
        end
      }
      
      2423
    end
    
    def send_sidebar(name, id, interface_id)
      @player.io.send_sidebar_interface 0, interface_id
      @player.io.send_interface_model interface_id+1, 200, id
      @player.io.send_string interface_id+3, name
    end
    
    def filter_name(name)
      name = name.dup
      MATERIALS.each {|m| name.gsub!(Regexp.new(m), "") }
      name.strip
    end
  end
end

# Interface container sizes
set_int_size(1688, 14)

# Listener
on_player_login(:equipment) {|player|
  # Have to send sidebar interfaces so the sidebar listener's update takes effect
  player.io.send_sidebar_interfaces
  
  # Register equipment container listeners
  player.equipment.add_listener Calyx::Item::InterfaceContainerListener.new(player, 1688)
  player.equipment.add_listener Calyx::Equipment::AppearanceContainerListener.new(player)
  player.equipment.add_listener Calyx::Equipment::SidebarContainerListener.new(player)
  player.equipment.add_listener Calyx::Item::WeightListener.new(player)
  player.equipment.add_listener Calyx::Item::BonusListener.new(player)
}

# Wield item
on_item_wield(3214) {|player, item, slot, name, id|
  if id == 4079 # Loop yo-yo
    player.play_animation Calyx::Model::Animation.new(1458) 
  elsif id == 6865 # Walk Marrionette(blue)
    player.play_animation Calyx::Model::Animation.new(3004)
    player.play_graphic Calyx::Model::Graphic.new(512, 2)
  elsif id == 6866 # Walk Marrionette(green)
    player.play_animation Calyx::Model::Animation.new(3004)
    player.play_graphic Calyx::Model::Graphic.new(516, 2)
  elsif id == 6867 # Walk Marrionette(red)
    player.play_animation Calyx::Model::Animation.new(3004)
    player.play_graphic Calyx::Model::Graphic.new(508, 2)
  else
    Calyx::Equipment.equip player, item, slot, name, id
  end
}

# Unwield item
on_item_option(1688) {|player, id, slot|
  Calyx::Item::Container.transfer player.equipment, player.inventory, slot, id
}
