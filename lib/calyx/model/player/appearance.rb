module Calyx::Player
  # Appearance of the player
  class Appearance
    @@types = [
      :gender,
      :hair_color,
      :torso_color,
      :leg_color,
      :feet_color,
      :skin_color,
      :head,
      :chest,
      :arms,
      :hands,
      :legs,
      :feet,
      :beard
    ]
    
    @@default_appearance = [
      0, 7, 8, 9, 5, 0 , 0, 18, 26, 33, 36, 42, 10
    ]
    
    @@types.each {|arg|
      attr_accessor arg
    }
    
    def initialize
      @@types.each_with_index {|arg, i|
        instance_variable_set("@#{arg.id2name}".to_sym, @@default_appearance[i])
      }
    end
    
    def get_look
      look = []
      @@types.each {|arg|
        look << instance_variable_get("@#{arg.id2name}".to_sym)
      }
      look
    end
    
    def set_look(look)
      @@types.each_with_index {|arg, i|
        instance_variable_set("@#{arg.id2name}".to_sym, look[i])
      }
    end
  end
end
