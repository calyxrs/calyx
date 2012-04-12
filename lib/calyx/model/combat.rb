module Calyx::Model
  # The types of damage.
  class HitType
    NO_DAMAGE = 0       # blue
    NORMAL_DAMAGE = 1   # red
    POISON_DAMAGE = 2   # green
    DISEASE_DAMAGE = 3  # orange
  end
  
  class Hit
    attr :type
    attr :damage
    
    def initialize(damage, type)
      @type = type
      @damage = damage
    end
  end
  
  class Damage
    attr :hit1
    attr :hit2
    
    def hit1_damage
      @hit1 == nil ? 0 : @hit1.damage
    end
    
    def hit2_damage
      @hit2 == nil ? 0 : @hit2.damage
    end
    
    def hit1_type
      @hit1 == nil ? 0 : @hit1.type
    end
    
    def hit2_type
      @hit2 == nil ? 0 : @hit2.type
    end
    
    def clear
      @hit1 = nil
      @hit2 = nil
    end
  end
end
