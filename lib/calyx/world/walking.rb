module Calyx::World
  MAXIMUM_SIZE = 50
  DIRECTION_DELTA_X = [-1, 0, 1, -1, 1, -1, 0, 1]
  DIRECTION_DELTA_Y = [1, 1, 1, 0, 0, -1, -1, -1]
  DIRECTIONS = [[5, 3, 0], [6, -1, 1], [7, 4, 2]]
  
  class Pathfinder
    attr :entity, :waypoints
    attr_accessor :run_toggle, :run_queue
    
    def initialize(entity)
      @entity = entity
      @waypoints = []
      @run_toggle = false
      @run_queue = false
    end
    
    def reset
      @run_queue = false
      @waypoints.clear
      @waypoints << Point.new(entity.location.x, entity.location.y, -1)
    end
    
    def empty?
      @waypoints.empty?
    end
    
    def finish
      @waypoints.shift
    end
    
    def add_step(x, y)
      reset if empty?
      last = @waypoints.last
      dx = x - last.x
      dy = y - last.y
      max = [dx.abs, dy.abs].max
      (0...max).each {
        dx += 0 <=> dx
        dy += 0 <=> dy
        add_step_internal x - dx, y - dy
      }
    end
    
    def next_movement
      if @entity.teleport_location != nil
        reset
        @entity.teleporting = true
        @entity.location = @entity.teleport_location
        @entity.teleport_location = nil
      else
        walk_point = next_point
        run_point = (@run_toggle || @run_queue) ? next_point : nil
        
        @entity.update_energy(run_point != nil) if @entity.instance_of?(Calyx::Model::Player)
        
        @entity.sprites[0] = walk_point ? walk_point.dir : -1
        @entity.sprites[1] = run_point ? run_point.dir : -1
      end
      
      dx = @entity.location.x - entity.last_location.get_region_x * 8
      dy = @entity.location.y - entity.last_location.get_region_y * 8
      @entity.region_change = dx < 16 || dx >= 88 || dy < 16 || dy >= 88
    end
    
    def running?
      @run_toggle || @run_queue
    end
    
    private
    
    def direction(dx, dy)
      x = (dx <=> 0) + 1
      y = (dy <=> 0) + 1
      DIRECTIONS[x][y]
    end
    
    def next_point
      p = @waypoints.shift
      return nil if p == nil || p.dir == -1
      dx = DIRECTION_DELTA_X[p.dir]
      dy = DIRECTION_DELTA_Y[p.dir]
      @entity.location = @entity.location.transform(dx, dy, 0)
      p
    end
    
    def add_step_internal(x, y)
      return if @waypoints.size >= MAXIMUM_SIZE
      last = @waypoints.last
      dir = direction(x - last.x, y - last.y)
      @waypoints << Point.new(x, y, dir) if dir > -1
    end
  end
  
  class Point
    attr :x, :y, :dir
    
    def initialize(x, y, dir)
      @x = x
      @y = y
      @dir = dir
    end
  end
end
