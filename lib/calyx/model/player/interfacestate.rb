module Calyx::Player
  class InterfaceState
    attr :player
    attr :listeners
    
    attr :current_interface
    
    # Enter amount data
    attr :enter_amount_interface
    attr :enter_amount_id
    attr :enter_amount_slot
    
    def initialize(player)
      @player = player
      
      @listeners = []
    end
    
    def interface_opened?(id)
      @current_interface == id
    end
    
    def interface_opened(id)
      interface_closed if @current_interface != -1
      @current_interface = id
    end
    
    def interface_closed
      @current_interface = -1
      @enter_amount_interface = -1
      @listeners.each {|e|
        @player.inventory.listeners.delete e
        @player.equipment.listeners.delete e
        @player.bank.listeners.delete e
      }
    end
    
    def add_listener(container, listener)
      container.add_listener listener
      @listeners << listener
    end
    
    def open_amount_interface(interface_id, slot, id)
      @enter_amount_interface = interface_id
      @enter_amount_slot = slot
      @enter_amount_id = id
      @player.io.send_amount_interface
    end
    
    def enter_amount_open?
      @enter_amount_interface != -1
    end
  end
end
