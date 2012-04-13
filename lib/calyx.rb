require 'logging'
require 'eventmachine'
require 'sqlite3'
require 'rufus/scheduler'
require 'ostruct'

module Calyx
  autoload :Server,             'calyx/server'
  
  module Engine
    autoload :EventManager,     'calyx/core/engine'
    autoload :Event,            'calyx/core/engine'
    autoload :QueuePolicy,      'calyx/core/engine'
    autoload :WalkablePolicy,   'calyx/core/engine'
    autoload :Action,           'calyx/core/engine' # TODO move to Actions
    autoload :ActionQueue,      'calyx/core/engine' # TODO move to Actions
  end
  
  module Misc
    autoload :AutoHash,            'calyx/core/util'
    autoload :HashWrapper,         'calyx/core/util'
    autoload :Flags,               'calyx/core/util'
    autoload :TextUtils,           'calyx/core/util'
    autoload :NameUtils,           'calyx/core/util'
    autoload :ThreadPool,          'calyx/core/util'
    autoload :Cache,               'calyx/core/cache'
  end
  
  module Actions
    autoload :HarvestingAction,    'calyx/core/actions'
  end
  
  module Model
    autoload :HitType,             'calyx/model/combat'
    autoload :Hit,                 'calyx/model/combat'
    autoload :Damage,              'calyx/model/combat'
    autoload :Animation,           'calyx/model/effects'
    autoload :Graphic,             'calyx/model/effects'
    autoload :ChatMessage,         'calyx/model/effects'
    autoload :Entity,              'calyx/model/entity'
    autoload :Location,            'calyx/model/location'
    autoload :Player,              'calyx/model/player'
    autoload :RegionManager,       'calyx/model/region'
    autoload :Region,              'calyx/model/region'
  end
  
  module Item
    autoload :Item,                       'calyx/model/item'
    autoload :ItemDefinition,             'calyx/model/item'
    autoload :Container,                  'calyx/model/item'
    autoload :ContainerListener,          'calyx/model/item'
    autoload :InterfaceContainerListener, 'calyx/model/item'
    autoload :WeightListener,             'calyx/model/item'
    autoload :BonusListener,              'calyx/model/item'
  end
  
  module NPC
    autoload :NPC,                 'calyx/model/npc'
    autoload :NPCDefinition,       'calyx/model/npc'
  end
  
  module Player
    autoload :Appearance,          'calyx/model/player/appearance'
    autoload :InterfaceState,      'calyx/model/player/interfacestate'
    autoload :RequestManager,      'calyx/model/player/requestmanager'
    autoload :Skills,              'calyx/model/player/skills'
  end
  
  module Net
    autoload :ActionSender,        'calyx/net/actionsender'
    autoload :ISAAC,               'calyx/net/isaac'
    autoload :Session,             'calyx/net/session'
    autoload :Connection,          'calyx/net/connection'
    autoload :Packet,              'calyx/net/packet'
    autoload :PacketBuilder,       'calyx/net/packetbuilder'
    autoload :JaggrabConnection,   'calyx/net/jaggrab'
  end
  
  module GroundItems
    autoload :GroundItem,          'calyx/services/ground_items'
    autoload :GroundItemEvent,     'calyx/services/ground_items'
    autoload :PickupItemAction,    'calyx/services/ground_items'
  end
  
  module Shops
    autoload :ShopManager,         'calyx/services/shops'
    autoload :Shop,                'calyx/services/shops'
  end
  
  module Objects
    autoload :ObjectManager,       'calyx/services/objects'
  end
  
  module Doors
    autoload :DoorManager,         'calyx/services/doors'
    autoload :Door,                'calyx/services/doors'
    autoload :DoubleDoor,          'calyx/services/doors'
    autoload :DoorEvent,           'calyx/services/doors'
  end
  
  module Tasks
    autoload :NPCTickTask,         'calyx/tasks/npc_update'
    autoload :NPCResetTask,        'calyx/tasks/npc_update'
    autoload :NPCUpdateTask,       'calyx/tasks/npc_update'
    autoload :PlayerTickTask,      'calyx/tasks/player_update'
    autoload :PlayerResetTask,     'calyx/tasks/player_update'
    autoload :PlayerUpdateTask,    'calyx/tasks/player_update'
    autoload :SystemUpdateEvent,   'calyx/tasks/sysupdate_event'
    autoload :UpdateEvent,         'calyx/tasks/update_event'
  end
  
  module World
    autoload :Profile,             'calyx/world/profile'
    autoload :Pathfinder,          'calyx/world/walking'
    autoload :Point,               'calyx/world/walking'
    autoload :World,               'calyx/world/world'
    autoload :LoginResult,         'calyx/world/world'
    autoload :Loader,              'calyx/world/world'
    autoload :YAMLFileLoader,      'calyx/world/world'
    autoload :NPCSpawns,           'calyx/world/npc_spawns'
    autoload :ItemSpawns,          'calyx/world/item_spawns'
  end
end

require 'calyx/plugin_hooks'
require 'calyx/net/packetloader'

