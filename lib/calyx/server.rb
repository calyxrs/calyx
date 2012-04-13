module Calyx
  class Server
    attr :config
    attr_accessor :updatemode
    attr_accessor :max_players
    
    def initialize
      @updatemode = false
      @max_players = 1000
      setup_logger
    end
    
    def setup_logger
      Logging.color_scheme( 'bright',
        :levels => {
          :info  => :green,
          :warn  => :yellow,
          :error => :red,
          :fatal => [:white, :on_red]
        },
        :date => :white,
        :logger => :white,
        :message => :white
      )
    
      Logging.logger.root.add_appenders(
        Logging.appenders.stdout(
          'stdout',
          :layout => Logging.layouts.pattern(
          :pattern => '[%d] %-5l %c: %m\n',
          :color_scheme => 'bright'
        )),
        Logging.appenders.file('data/logs/development.log', :layout => Logging.layouts.pattern(:pattern => '[%d] %-5l %c: %m\n'))
      )
      
      @log = Logging.logger['server']
    end
  
    def start_config(config)
      @config = config
      init_cache
      load_int_hooks
      load_defs
      load_hooks
      load_config
      bind
    end
    
    def reload
      HOOKS.clear
      load_hooks
      load_int_hooks
      Calyx::Net.load_packets
    end
    
    # Load hooks
    def load_hooks
      Dir["./plugins/*.rb"].each {|file| load file }
    end
    
    def load_int_hooks
      Dir["./plugins/internal/*.rb"].each {|file| load file }
    end
    
    def init_cache
      begin
        $cache = Calyx::Misc::Cache.new("./data/cache/")
      rescue Exception => e
        $cache = nil
        Logging.logger['cache'].warn e.to_s
      end
    end
    
    def load_defs
      Calyx::Item::ItemDefinition.load
      
      # Equipment
      Calyx::Equipment.load
    end
    
    def load_config
      WORLD.shop_manager.load_shops
      WORLD.door_manager.load_single_doors
      WORLD.door_manager.load_double_doors
      
      Calyx::World::NPCSpawns.load
      Calyx::World::ItemSpawns.load
    end
    
    # Binds the server socket and begins accepting player connections.
    def bind
      EventMachine.run do
        Signal.trap("INT") {
          WORLD.players.each {|p|
            WORLD.unregister(p)
          }
          
          while WORLD.work_thread.waiting > 0
            sleep(0.01)
          end
          
          EventMachine.stop if EventMachine.reactor_running?
          exit
        }
        
        Signal.trap("TERM") {
          EventMachine.stop
        }
        
        EventMachine.start_server("0.0.0.0", @config.port + 1, Calyx::Net::JaggrabConnection) if $cache
        EventMachine.start_server("0.0.0.0", @config.port, Calyx::Net::Connection)
        @log.info "Ready on port #{@config.port}"
      end
    end
  end
end
