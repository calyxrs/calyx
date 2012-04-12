module Calyx::Model
  class Player < Calyx::Model::Entity
    # The EventMachine connection.
    attr :connection
    attr :session
    attr :in_cipher
    attr :out_cipher
        
    # Info
    attr :uid
    attr :name
    attr :name_long
    attr :password
    attr :appearance
    attr_accessor :rights
    attr_accessor :members
    
    # Items
    attr :skills
    attr :equipment
    attr :inventory
    attr :bank
    attr_accessor :settings
    
    # Trade
    attr :request_manager
    attr :offered_items
    attr :gained_items
    attr_accessor :current_shop
    
    # Interaction
    attr :action_queue
    attr_accessor :used_loc
    attr_accessor :used_item
    
    # Misc
    attr_accessor :model
    
    attr :interface_state
    attr :io
    
    # Chat information
    attr :chat_queue
    attr_accessor :current_chat_message
    
    # Data
    attr :var   # non-persistent data
    attr :varp  # persistent data
    
    def initialize(session)
      super()
      @connection = session.connection
      @session = session
      @in_cipher = session.in_cipher
      @out_cipher = session.out_cipher
      @uid = session.uid
      @name = session.username
      @name_long = Calyx::Misc::NameUtils.name_to_long(@name) #session.name_long
      @password = session.password
      @appearance = Calyx::Player::Appearance.new
      @skills = Calyx::Player::Skills.new(self)
      
      @var = OpenStruct.new
      @varp = OpenStruct.new
      
      @interface_state = Calyx::Player::InterfaceState.new self
      @io = Calyx::Net::ActionSender.new(self)
      @action_queue = Calyx::Engine::ActionQueue.new
      
      @rights = :player
      @members = true
      @model = -1
      
      @flags.flag :appearance
      @teleporting = true
      
      @equipment = Calyx::Item::Container.new false, 14
      @inventory = Calyx::Item::Container.new false, 28
      @bank = Calyx::Item::Container.new true, 352
      @settings = {}
        
      @request_manager = Calyx::Player::RequestManager.new
      @offered_items = Calyx::Item::Container.new false, 28
      @gained_items = Calyx::Item::Container.new false, 28
      
      @chat_queue = []
      @current_chat_message = nil
    end
    
    def change_session(session)
      @connection = session.connection
      @session = session
      @in_cipher = session.in_cipher
      @out_cipher = session.out_cipher
      @uid = session.uid
      @name = session.username
      @name_long = Calyx::Misc::NameUtils.name_to_long(@name)
      @password = session.password
    end
    
    def add_to_region(region)
      region.players << self
    end
    
    def remove_from_region(region)
      region.players.delete self
    end
    
    def update_energy(running)
      @settings[:energy] ||= 100.0
      
      energy = @settings[:energy]
      
      if running
        # Decrease, we're running
        energy -= 0.6
      else
        # Increase, we're standing/walking
        energy += 0.2
      end
      
      # Cap 0 < energy < 100
      energy = 100.0 if energy > 100.0
      energy = 0.0 if energy < 0.0
      
      # Turn off if we're out of energy
      if running && energy < 1.0
        @walking_queue.run_toggle = false
        @settings[:move_speed] = 0
        @io.send_config 173, 0
      end
      
      # Save energy state
      @settings[:energy] = energy
      
      # Update client
      @connection.send_data Calyx::Net::PacketBuilder.new(110).add_byte(@settings[:energy].to_i).to_packet
    end
  end
end
