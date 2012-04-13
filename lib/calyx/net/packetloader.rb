PACKETS = {}

def on_packet(*ids, &block)
  ids.each {|id|
    PACKETS[id] = block
  }
end

module Calyx
  module Calyx::Net
    def Net.load_packets
      # Reset old packet handlers
      PACKETS.clear
      
      # Parse files
      Dir["./plugins/packets/*.rb"].each {|file| load file }
    end
    
    def Net.handle_packet(player, packet)
      return if !player
    
      if PACKETS.include?(packet.opcode)
        handler = PACKETS[packet.opcode]
        
        if handler.instance_of?(Proc)
          handler.call(player, packet)
        end
      else
        Logging.logger['packets'].warn "Unhandled packet: id = #{packet.opcode}, length = #{packet.buffer.length}, payload = #{Net.hexstr(packet.buffer)}"
      end
    end
    
    def Net.hexstr(src)
      dest = ""
      src.each_byte {|b|
        dest << (b < 16 ? "0" : "") + b.to_s(16) + " "
      }
      dest.strip
    end
  end
end

Calyx::Net.load_packets

