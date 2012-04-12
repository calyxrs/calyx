module Calyx::Model
  # Any sort of animation in the game
  class Animation
    attr :id
    attr :delay
    
    def initialize(id, delay = 0)
      @id = id
      @delay = delay
    end
  end
  
  # Any sort of graphic in the game
  class Graphic
    attr :id
    attr :delay
    
    def initialize(id, delay = 0)
      @id = id
      @delay = delay
    end
  end
  
  # Chat box message
  class ChatMessage
    attr :color
    attr :effects
    attr :text
    
    def initialize(color, effects, text)
      @color = color
      @effects = effects
      @text = text
    end
  end
end
