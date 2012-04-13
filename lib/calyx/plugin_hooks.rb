HOOKS ||= Calyx::Misc::AutoHash.new

# Controls
def on_mouse_click(trigger = :default, &block)
  HOOKS[:mouse_click][trigger] = block
end

def on_camera_move(trigger = :default, &block)
  HOOKS[:camera_move][trigger] = block
end

# Chat
def on_chat(trigger = :default, &block)
  HOOKS[:chat][trigger] = block
end

def on_command(name, rights = :player, &block)
  HOOKS[:command][name] = lambda {|player, params|
    if Calyx::World::RIGHTS.index(player.rights) >= Calyx::World::RIGHTS.index(rights)
      block.call(player, params)
    end
  }
end

# Interface
def on_int_button(id, &block)
  HOOKS[:int_button][id] = block
end

def on_int_enter_amount(id, &block)
  HOOKS[:int_enteramount][id] = block
end

def on_int_close(id, &block)
  HOOKS[:int_close][id] = block
end

def set_int_size(id, size)
  HOOKS[:int_size][id] = size
end

# Item
def on_item_click(id, &block)
  HOOKS[:item_click1][id] = block
end

def on_item_click2(id, &block)
  HOOKS[:item_click2][id] = block
end

def on_item_drop(id, &block)
  HOOKS[:item_drop][id] = block
end

def on_item_wield(interface_id, &block)
  HOOKS[:item_wield][interface_id] = block
end

def on_item_option(id, &block)
  HOOKS[:item_option1][id] = block
end

def on_item_option2(id, &block)
  HOOKS[:item_option2][id] = block
end

def on_item_option3(id, &block)
  HOOKS[:item_option3][id] = block
end

def on_item_option4(id, &block)
  HOOKS[:item_option4][id] = block
end

def on_item_option5(id, &block)
  HOOKS[:item_option5][id] = block
end

def on_item_alt2(id, &block)
  HOOKS[:item_alt2][id] = block
end

def on_item_on_ground(id, &block)
  HOOKS[:item_on_ground][id] = block
end

def on_item_swap(interface_id, &block)
  HOOKS[:item_swap][interface_id] = block
end

def on_item_on_item(first_id, second_id, &block)
  HOOKS[:item_on_item][[first_id, second_id].sort] = block
end

def on_item_on_floor(inv_id, floor_id, &block)
  HOOKS[:item_on_floor][[inv_id, floor_id]] = block
end

def on_item_on_obj(item_id, object_id, &block)
  HOOKS[:item_on_obj][[item_id, object_id]] = block
end

def on_item_on_player(id, &block)
  HOOKS[:item_on_player][id] = block
end

def on_item_on_npc(id, npc_id, &block)
  HOOKS[:item_on_npc][[id, npc_id]] = block
end

# Object
def on_obj_option(id, &block)
  HOOKS[:obj_click1][id] = block
end

def on_obj_option2(id, &block)
  HOOKS[:obj_click2][id] = block
end

def on_obj_option3(id, &block)
  HOOKS[:obj_click3][id] = block
end

# Player
def on_player_trade(id, &block)
  HOOKS[:trade_option][id] = block
end

def on_player_login(trigger = :default, &block)
  HOOKS[:player_login][trigger] = block
end

def on_player_logout(trigger = :default, &block)
  HOOKS[:player_logout][trigger] = block
end

# Magic
def on_magic_on_item(spell_id, &block)
  HOOKS[:magic_on_item][spell_id] = block
end

def on_magic_on_floor(item_id, spell_id, &block)
  HOOKS[:magic_on_flooritem][[item_id, spell_id]] = block
end

def on_magic_on_npc(spell_id, &block)
  HOOKS[:magic_on_npc][spell_id] = block
end

def on_magic_on_player(spell_id, &block)
  HOOKS[:magic_on_player][spell_id] = block
end

# NPC
def on_npc_option(id, &block)
  HOOKS[:npc_option1][id] = block
end

def on_npc_option2(id, &block)
  HOOKS[:npc_option2][id] = block
end

def on_npc_option3(id, &block)
  HOOKS[:npc_option3][id] = block
end

def on_npc_attack(id, &block)
  HOOKS[:npc_attack][id] = block
end
