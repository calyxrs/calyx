module Woodcutting
  class Tree
    attr_accessor :log
    attr_accessor :level
    attr_accessor :xp
    attr_accessor :objects
    
    def initialize(log, level, xp, objects)
      @log = log
      @level = level
      @xp = xp
      @objects = objects
    end
  end
  
  @@axes = {
    1359 => {:level => 41, :anim => 867},
    1357 => {:level => 31, :anim => 869},
    1355 => {:level => 21, :anim => 871},
    1361 => {:level => 6, :anim => 873},
    1353 => {:level => 6, :anim => 875},
    1349 => {:level => 1, :anim => 877},
    1351 => {:level => 1, :anim => 879},
  }
  
  def self.axes
    @@axes
  end
  
  @@tree_types = [
    Tree.new(1511, 1, 50,
      [1276, 1277, 1278, 1279, 1280, 1282, 1283,
       1284, 1285, 1286, 1289, 1290, 1291, 1315, 1316,
       1318, 1319, 1330, 1331, 1332, 1365, 1383, 1384,
       2409, 3033, 3034, 3035, 3036, 3881, 3882,
       3883, 5902, 5903, 5904]),
    Tree.new(1519, 30, 135, [1308, 5551, 5552, 5553]),
    Tree.new(1521, 15, 75, [1281, 3037]),
    Tree.new(1513, 75, 500, [1292, 1306]),
    Tree.new(1517, 45, 200, [1307, 4677]),
    Tree.new(6332, 50, 250, [9034]),
    Tree.new(6333, 35, 170, [9036]),
    Tree.new(2862, 1, 50, [2023]),
    Tree.new(1515, 60, 350, [1309]),
  ]
  
  @@trees = {}
  @@tree_types.each {|tree|
    tree.objects.each {|id|
      @@trees[id] = tree
    }
  }
  
  class WoodcuttingAction < Calyx::Actions::HarvestingAction
    attr_accessor :cycle_count
    attr_accessor :tree
    attr_accessor :axe
    
    def initialize(player, loc, tree)
      super(player, loc)
      @tree = tree
      @cycle_count = 0
    end
     
    def init
      level = player.skills.skills[:woodcutting]
      
      # Check if we have a axe we can use
      @axe = ::Woodcutting.axes.find {|h, v|
        player.equipment.contains(h) || player.inventory.contains(h) && level >= v[:level]
      }
      
      # Replace with value (hash)
      @axe = @axe[1] unless @axe == nil
      
      if @axe == nil
        player.io.send_message "You do not have an axe for which you have the level to use."
        stop
        return
      end
      
      # Check if we can cut this tree
      if level < @tree.level
        player.io.send_message "You do not have the required level to cut down this tree."
        stop
        return
      end
      
      player.io.send_message "You swing your axe at the tree..."
      @cycle_count = calculate
    end
    
    def calculate
      wc = player.skills.skills[:woodcutting]
      @cycle_count = ((@tree.level * 60 - wc * 20) / @axe[:level] * 0.25 - rand(3) * 4).ceil
      @cycle_count = 1 if @cycle_count < 1
      @cycle_count.to_i
    end
    
    def harvested_item; Calyx::Item::Item.new(@tree.log, 1) end
    
    def experience; @tree.xp end
    
    def animation; Calyx::World::Animation.new(@axe[:anim]) end
    
    def skill; :woodcutting end
    
    def harvest_delay; 3000 end
    
    def periodic_rewards; true end
    
    def factor; 0.5 end
    
    def cycles; @tree.level == 1 ? 1 : @cycle_count end
  end
  
  @@trees.each {|id, data|
    on_obj_option(id) {|player, loc|
      player.io.send_message loc.to_s
    
      object = Calyx::Objects::Object.new(1342, loc, 0, 10, 1278, loc, 0, 3)
      object.change
      
      # Add this to the object manager
      WORLD.object_manager.objects << object
      
      #player.action_queue.add WoodcuttingAction.new(player, loc, data)
    }
  }
end

