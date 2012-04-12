module Cooking
  @@stoves = [114, 5981, 6093, 6094, 6095, 6096]
  @@food = [
    {:raw => 2307, :burnt => 2311, :cooked => 2309, :xp => 40, :lvl => 1, :stop => 50},
    {:raw => 321, :burnt => 323, :cooked => 319, :xp => 30, :lvl => 1, :stop => 34},
  ]
  
  def self.get_food(id)
    @@food.find {|v| v[:raw] == id}
  end
    
  def self.is_food?(id)
   get_food(id) != nil
  end
  
  @@food.each {|food|
    @@stoves.each {|stove|
      item = food[:raw]
      on_item_on_obj(item, stove) {|player, loc|
        if player.inventory.count(item) > 1
          player.io.send_chat_interface 1743
          player.io.send_interface_model 13716, 175, item
          player.io.send_string 13717, Calyx::Item::ItemDefinition.for_id(item).name
        else
          player.action_queue.add CookAction.new(player, loc, item)
        end
      }
    }
  }
  
  on_int_button(13720) {|player|
    player.action_queue.add CookAction.new(player, player.used_loc, player.used_item)
  }
  
  on_int_button(13719) {|player|
    player.action_queue.add CookAction.new(player, player.used_loc, player.used_item, 5)
  }
   
  on_int_button(13717) {|player|
    player.action_queue.add CookAction.new(player, player.used_loc, player.used_item, player.inventory.count(player.used_item))
  }
  
  on_int_button(13718) {|player|
    player.interface_state.open_amount_interface(1743, -1, -1)
  }
  
  on_int_enter_amount(1743) {|player, enterAmountId, enterAmountSlot, amount|
    player.action_queue.add CookAction.new(player, player.used_loc, player.used_item, amount)
  }
  
  class CookAction < Calyx::Engine::Action
    attr_accessor :face
    attr_accessor :food
    attr_accessor :amount
    attr_accessor :count
    
    def initialize(player, face, item, amount = 1)
      super(player, 0)
      @face = face
      @food = ::Cooking.get_food(item)
      @amount = amount
      @count = 0
      @stage = :precheck
      
      if player.inventory.count(item) < @amount
        @amount = player.inventory.count(item)
      end
      
      # close enter amount interface if there is one
      player.io.send_clear_screen
    end
    
    def precheck
      can_use = player.skills.skills[:cooking] >= @food[:lvl]
      @player.face @face if running
      player.io.send_message "You need a cooking level of #{@food[:lvl]} to cook this item." unless can_use
      can_use
    end
    
    def execute
      case @stage
      when :precheck
        # Make sure we have the required level to cook this.
        if precheck
          @stage = :animation
          @delay = 0
        else
          stop
          return
        end
      when :animation
        if @count < @amount
          @player.play_animation Calyx::Model::Animation.new(883)
          @stage = :cook
          @delay = 600 * 4
        else
          stop
        end
      when :cook
        cook_item
        @stage = :animation
        @delay = 0
      end
    end
    
    def cook_item
      chance = 52 - ((player.skills.skills[:cooking] - @food[:lvl]) * (52 / (@food[:stop] - @food[:lvl])))
      item_name = Calyx::Item::ItemDefinition.for_id(@food[:cooked]).name.downcase
      
      player.inventory.remove -1, Calyx::Item::Item.new(@food[:raw])
        
      if chance <= rand * 100.0
        player.inventory.add Calyx::Item::Item.new(@food[:cooked])
        player.skills.add_exp :cooking, @food[:xp]
        player.io.send_message "You successfully cook the #{item_name}."
      else
        player.inventory.add Calyx::Item::Item.new(@food[:burnt])
        player.io.send_message "You accidentally burn the #{item_name}."
      end
      
      @count += 1
    end
    
    def queue_policy
      Calyx::Engine::QueuePolicy::ALWAYS
    end
    
    def walkable_policy
      Calyx::Engine::WalkablePolicy::WALKABLE
    end
  end
end
