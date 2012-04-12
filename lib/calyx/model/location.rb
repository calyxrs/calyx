module Calyx::Model
  # Physical location in the world
  class Location
    attr :x
    attr :y
    attr :z
    
    def initialize(x, y, z)
      @x = x
      @y = y
      @z = z
    end
    
    def get_local_x(loc = self)
      @x - 8 * loc.get_region_x
    end
    
    def get_local_y(loc = self)
      @y - 8 * loc.get_region_y
    end
    
    def get_region_x
      (@x >> 3) - 6
    end
    
    def get_region_y
      (@y >> 3) - 6
    end
    
    def within_distance?(loc)
      return false unless @z == loc.z
      dx = loc.x - @x
      dy = loc.y - @y
      (-15..14) === dx && (-15..14) === dy
    end
    
    def within_interaction_distance?(loc)
      return false unless @z == loc.z
      dx = loc.x - @x
      dy = loc.y - @y
      (-3..2) === dx && (-3..2) === dy
    end
    
    def ==(other)
      return unless other.instance_of? self.class
      @x == other.x && @y == other.y && @z == other.z
    end
    
    def inspect
      "[#{@x},#{@y},#{@z}]"
    end
    
    def to_s
      inspect
    end
    
    def transform(x_offset, y_offset, z_offset)
      Location.new(@x+x_offset, @y+y_offset, @z+z_offset)
    end
  end
end
