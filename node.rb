$:.unshift File.join(File.dirname(__FILE__), "lib")

require 'bundler/setup'
require 'calyx'

WORLD = Calyx::World::World.new
SERVER = Calyx::Server.new
SERVER.start_config(Calyx::Misc::HashWrapper.new({:port => 43594}))

