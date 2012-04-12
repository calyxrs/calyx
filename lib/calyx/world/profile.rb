module Calyx::World
  class Profile
    #include MongoMapper::Document
    
    #set_collection_name "profiles"
    
    #key :hash, Integer
    #key :node, String
    #key :banned, Boolean
    #key :member, Boolean
    #key :x, Integer
    #key :y, Integer
    #key :z, Integer
    #key :appearance, Array
    #key :skills, Array
    #key :equipment, Array
    #key :inventory, Array
    #key :bank, Array
    #key :friends, Array
    #key :ignores, Array
    
    attr_accessor :hash
    attr_accessor :node
    attr_accessor :banned
    attr_accessor :member
    attr_accessor :x
    attr_accessor :y
    attr_accessor :z
    attr_accessor :appearance
    attr_accessor :skills
    attr_accessor :equipment
    attr_accessor :inventory
    attr_accessor :bank
    attr_accessor :friends
    attr_accessor :ignores
    attr_accessor :settings
  end
end
