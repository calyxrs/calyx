module Calyx::Player
  # Skills
  class Skills
    MAX_EXP = 200000000
    SKILLS = [
      :attack,
      :defence,
      :strength,
      :hitpoints,
      :range,
      :prayer,
      :magic,
      :cooking,
      :woodcutting,
      :fletching,
      :fishing,
      :firemaking,
      :crafting,
      :smithing,
      :mining,
      :herblore,
      :agility,
      :thieving,
      :slayer,
      :farming,
      :runecrafting
    ]
    attr :skills
    attr :exps
    attr :player
    
    def initialize(player)
      @player = player
      
      @skills ||= {}
      @exps ||= {}
      
      SKILLS.each {|skill|
        @skills[skill] = 1
        @exps[skill] = 0
      }
      # Start with 10 hitpoints
      @skills[:hitpoints] = 10
      @exps[:hitpoints] = 1184
    end
    
    def combat_level
      attack = level_for_exp :attack
      defence = level_for_exp :defence
      strength = level_for_exp :strength
      hitpoints = level_for_exp :hitpoints
      prayer = level_for_exp :prayer
      range = level_for_exp :range
      magic = level_for_exp :magic

      combat = ((defence + hitpoints + (prayer / 2).floor) * 0.2535).to_i + 1
      melee = (attack + strength) * 0.325
      ranger = (range * 1.5).to_i.floor * 0.325
      mage = (magic * 1.5).to_i.floor * 0.325
      
      combat += melee if melee >= ranger && melee >= mage
      combat += ranger if ranger >= melee && ranger >= mage
      combat += mage if mage >= melee && mage >= ranger
      
      combat <= 126 ? combat : 126
    end
    
    def total_level
      total = 0
      @skills.each {|skill|
        total = total + level_for_exp(skill)
      }
      total
    end
    
    def level_for_exp(skill)
      exp = @exps[skill]
      points = 0

      lvl = 1
      (1..99).each {
        points = points + (lvl + 300.0 * (2.0 ** (lvl / 7.0))).floor
        output = (points / 4).floor
        
        return lvl if output > exp
        
        lvl += 1
      }
      
      99
    end
    
    def exp_for_level(skill)
      level = @skills[skill]
      points = 0
      output = 0
      
      lvl = 1
      (1..level).each {
        points = points + (lvl + 300.0 * (2.0 ** (lvl / 7.0))).floor
        
        return output if lvl >= level
        
        output = (points / 4).floor
        
        lvl += 1
      }
      
      0
    end
    
    def set_skill(skill, level, exp, send=true)
      @skills[skill] = level
      @exps[skill] = exp
      player.io.send_skill(skill) if send
    end
    
    def set_level(skill, level)
      @skills[skill] = level
      player.io.send_skill skill
    end
    
    def increase_level(skill)
      @skills[skill] = @skills[skill] + 1
      player.io.send_skill skill
    end
    
    def decrease_level(skill)
      @skills[skill] = @skills[skill] - 1
      player.io.send_skill skill
    end
    
    def detract_level(skill, amount)
      amount = 0 if @skills[skill] == 0
      amount = @skills[skill] if amount > @skills[skill]
      
      @skills[skill] = @skills[skill] - amount
      player.io.send_skill skill
    end
    
    def normalize_level(skill)
      normal = level_for_exp skill
      
      @skills[skill] += normal <=> @skills[skill]
      player.io.send_skill skill
    end
    
    def add_exp(skill, exp)
      old = @skills[skill]
      @exps[skill] += exp
      
      @exps[skill] = MAX_EXP if @exps[skill] > MAX_EXP
      
      new = level_for_exp skill
      diff = new - old
      
      if diff > 0
        @skills[skill] += diff
        player.flags.flag :appearance
      end
      
      player.io.send_skill skill
    end
  end
end
