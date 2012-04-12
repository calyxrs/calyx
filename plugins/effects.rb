@@effects = [
  {:id => 4079, :hook => :item_click, :anim => 1457}, # Play yo-yo
  {:id => 6865, :hook => :item_click, :anim => 3003, :graphic => 511, :gdelay => 2}, # Jump Marionette(blue)
  {:id => 6866, :hook => :item_click, :anim => 3003, :graphic => 515, :gdelay => 2}, # Jump Marionette(green)
  {:id => 6867, :hook => :item_click, :anim => 3003, :graphic => 507, :gdelay => 2}, # Jump Marionette(red)
        
  {:id => 4079, :hook => :item_click2, :anim => 1460}, # Crazy yo-yo
  {:id => 6865, :hook => :item_click2, :anim => 3006, :graphic => 514, :gdelay => 2}, # Dance Marionette(blue)
  {:id => 6866, :hook => :item_click2, :anim => 3006, :graphic => 518, :gdelay => 2}, # Dance Marionette(green)
  {:id => 6867, :hook => :item_click2, :anim => 3006, :graphic => 510, :gdelay => 2}, # Dance Marionette(red)
      
  {:id => 4079, :hook => :item_alt2, :anim => 1459}, # Walk yo-yo
  {:id => 6865, :hook => :item_alt2, :anim => 3005, :graphic => 513, :gdelay => 2}, # Bow Marionette(blue)
  {:id => 6866, :hook => :item_alt2, :anim => 3005, :graphic => 517, :gdelay => 2}, # Bow Marionette(green)
  {:id => 6867, :hook => :item_alt2, :anim => 3005, :graphic => 509, :gdelay => 2}  # Bow Marionette(red)
]

@@effects.each {|item|
  method("on_#{item[:hook]}").call(item[:id]) {|player, slot|
    if item.include?(:anim)
      player.play_animation Calyx::Model::Animation.new(item[:anim], item[:adelay] || 0)
    end
    if item.include?(:graphic)
      player.play_graphic Calyx::Model::Graphic.new(item[:graphic], item[:gdelay] || 0)
    end
  }
}
