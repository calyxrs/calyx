require 'eventmachine'
require 'socket'

module Calyx::Net
  # Connection throttling
  CONNECTION_TIMES = {}
  CONNECTION_COUNTS = {}
  CONNECTION_INTERVAL = 1.0
  CONNECTION_MAX = 5
  
  # The client sends this value when connecting to the game server.
  OPCODE_GAME = 14
  
  # The client sends this value when connecting to the update server.
  OPCODE_UPDATE = 15
  
  # Server status pages use this to get the number of users online.
  OPCODE_PLAYERCOUNT = 16
  
  # Contains sizes for all of the packets. If an index contains a negative number, it is of variable length.
  PACKET_SIZES = [
    0, 0, 0, 1, -1, 0, 0, 0, 0, 0, # 0
    0, 0, 0, 0, 8, 0, 6, 2, 2, 0,  # 10
    0, 2, 0, 6, 0, 12, 0, 0, 0, 0, # 20
    0, 0, 0, 0, 0, 8, 4, 0, 0, 2,  # 30
    2, 6, 0, 6, 0, -1, 0, 0, 0, 0, # 40
    0, 0, 0, 12, 0, 0, 0, 8, 0, 0, # 50
    0, 8, 0, 0, 0, 0, 0, 0, 0, 0,  # 60
    6, 0, 2, 2, 8, 6, 0, -1, 0, 6, # 70
    0, 0, 0, 0, 0, 1, 4, 6, 0, 0,  # 80
    0, 0, 0, 0, 0, 3, 0, 0, -1, 0, # 90
    0, 13, 0, -1, 0, 0, 0, 0, 0, 0,# 100
    0, 0, 0, 0, 0, 0, 0, 6, 0, 0,  # 110
    1, 0, 6, 0, 0, 0, -1, 0, 2, 6, # 120
    0, 4, 6, 8, 0, 6, 0, 0, 0, 2,  # 130
    0, 0, 0, 0, 0, 6, 0, 0, 0, 0,  # 140
    0, 0, 1, 2, 0, 2, 6, 0, 0, 0,  # 150
    0, 0, 0, 0, -1, -1, 0, 0, 0, 0,# 160
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  # 170
    0, 8, 0, 3, 0, 2, 0, 0, 8, 1,  # 180
    0, 0, 12, 0, 0, 0, 0, 0, 0, 0, # 190
    2, 0, 0, 0, 0, 0, 0, 0, 4, 0,  # 200
    4, 0, 0, 0, 7, 8, 0, 0, 10, 0, # 210
    0, 0, 0, 0, 0, 0, -1, 0, 6, 0, # 220
    1, 0, 0, 0, 6, 0, 6, 8, 1, 0,  # 230
    0, 4, 0, 0, 0, 0, -1, 0, -1, 4,# 240
    0, 0, 6, 6, 0, 0, 0            # 250
  ]
  
  LOG = Logging.logger['net']
  
  class Connection < EM::Connection
    # The current state of the connection.
    attr :state
    
    # The connection credentials, once they have been validated.
    attr :session
    
    # The connection address.
    attr :ip

    # Called when the connection has been opened.
    def post_init
      @state = :opcode
      @buffer = Packet.new(-1, :RAW, "")
      @popcode = -1
      @psize = -1
      port, @ip = Socket.unpack_sockaddr_in(get_peername)
      
      response, throttled = should_throttle
      
      if throttled
        LOG.warn "Throttling connection"
        send_data ([0] * 8 + [response]).pack("C" * 9)
        close_connection_after_writing
      else
        LOG.debug "Connection opened"
      end
    end
    
    def should_throttle
      # Increase connection count
      CONNECTION_COUNTS[@ip] = CONNECTION_COUNTS.include?(@ip) ? CONNECTION_COUNTS[@ip] + 1 : 1
      
      # Limit connection time
      time_exceeded = CONNECTION_TIMES.include?(@ip) && (Time.now - CONNECTION_TIMES[@ip] < CONNECTION_INTERVAL)
      
      CONNECTION_TIMES[@ip] = Time.now
      
      if time_exceeded
        return 16, true
      end
      
      # Limit connection count
      if CONNECTION_COUNTS[@ip] > CONNECTION_MAX
        return 9, true
      end
      
      LOG.debug "#{CONNECTION_COUNTS[@ip]} connections now from #{@ip}"
      
      return 0, false
    end
    
    # Sends data back
    def send_data(data)
      if data.instance_of? Packet
        if data.type == :RAW
          super data.buffer
        else
          out_buffer = [data.opcode+@session.out_cipher.next_value.ubyte]
          out_types = "C"
          
          if data.type != :FIXED
            out_buffer << data.buffer.size
            out_types << (data.type == :VARSH ? "n" : "C")
          end
          
          super out_buffer.pack(out_types) + data.buffer
        end
      else
        super
      end
    end

    # Reads data into the buffer, and runs process_buffer on the received data.
    def receive_data(data)
      @buffer << data unless data.empty?
      process_buffer
    end
    
    # Handles each stage of the connection process. If any invalid data is received, the connection is closed and an error response may be sent.
    def process_buffer(lim = 0)
      return if lim >= 32
      return if @buffer.empty?
      
      case @state
      when :opcode
        if @buffer.length >= 1
          opcode = @buffer.read_byte

          if opcode == OPCODE_PLAYERCOUNT
            LOG.debug "Connection type: online"
            send_data [WORLD.players.size].pack("n")
            close_connection true
          elsif opcode == OPCODE_UPDATE
            LOG.debug "Connection type: update"
            send_data (Array.new(8, 0)).pack("C" * 8)
            @state = :update
          elsif check_failed(opcode == OPCODE_GAME, "Invalid opcode: #{opcode}")
            return
          else
            LOG.debug "Connection type: client"
            @state = :login
          end
        end
      when :update
        if @buffer.length >= 4
          cache_id = @buffer.read_byte.ubyte
          file_id = @buffer.read_short.ushort
          priority = @buffer.read_byte.ubyte
          
#          Logging.logger['cache'].debug "update server request (cache: #{cache_id}, file: #{file_id}, prio: #{priority})"
          
          data = $cache.get(cache_id + 1, file_id)
          total_size = data.size
          rounded_size = total_size
          rounded_size += 1 while rounded_size % 500 != 0
          blocks = rounded_size / 500
          sent_bytes = 0
          
          blocks.times do |i|
            pb = PacketBuilder.new(-1, :RAW)
            block_size = total_size - sent_bytes
            
            pb.add_byte cache_id
            pb.add_short file_id
            pb.add_short total_size
            pb.add_byte i
            
            block_size = 500 if block_size > 500
            
            pb.buffer << data.slice(sent_bytes, block_size)
            
            sent_bytes += block_size
            send_data pb.to_packet
          end
        end
      when :login
        if @buffer.length >= 1
          # Name hash
          @buffer.read_byte

          # Generate server key
          @server_key = rand(1 << 32)
          @state = :precrypted

          # Server update check
          return if check_failed(SERVER.updatemode == false, "Server is in update mode"){
            send_data (Array.new(8, 0) + [14]).pack("C" * 8 + "C")
          }
          
          # World full check
          return if check_failed(WORLD.players.size < SERVER.max_players, "World full"){
            send_data (Array.new(8, 0) + [7]).pack("C" * 8 + "C")
          }
          
          # Send response
          response = Array.new(8, 0)
          response << 0
          response << @server_key
          send_data response.pack("C" * 8 + "C" + "q")
        end
      when :precrypted
        if @buffer.length >= 2
          # Parse login opcode
          login_opcode = @buffer.read_byte.ubyte
          return if check_failed([16, 18].include?(login_opcode), "Invalid login opcode: #{login_opcode}")
          
          # Parse login packet size
          login_size = @buffer.read_byte.ubyte
          enc_size = login_size - (36 + 1 + 1 + 2)
          return if check_failed(enc_size >= 1, "Encrypted packet size zero or negative: #{enc_size}")

          @state = :crypted
          @login_size = login_size
          @enc_size = enc_size
        end
      when :crypted
        if @buffer.length >= @login_size
          # Magic ID
          magic = @buffer.read_byte.ubyte
          return if check_failed(magic == 255, "Incorrect magic ID: #{magic}")

          # Version
          version = @buffer.read_short.ushort
          return if check_failed(version == (SERVER.config.client_version || 317), "Incorrect client version: #{version}"){
            send_data [6].pack("C")
          }

          # Low memory
          @buffer.read_byte

          9.times { @buffer.read_int }

          @enc_size -= 1

          reported_size = @buffer.read_byte.ubyte
          return if check_failed(reported_size == @enc_size, "Packet size mismatch (expected: #{@enc_size}, reported: #{reported_size})")

          block_opcode = @buffer.read_byte.ubyte
          return if check_failed(block_opcode == 10, "Invalid login block opcode: #{block_opcode}")

          # Check to see that the keys match
          client_key = [@buffer.read_int, @buffer.read_int]
          server_key = [@buffer.read_int, @buffer.read_int]
          reported_server_key = server_key.pack("NN").unpack("q").first
          return if check_failed(reported_server_key == @server_key, "Server key mismatch (expected: #{@server_key}, reported: #{reported_server_key})"){
            send_data [10].pack("C") # "Bad session id"
          }

          # Read credentials
          uid = @buffer.read_int
          username = Calyx::Misc::NameUtils.format_name_protocol(@buffer.read_str)
          password = @buffer.read_str
          return if check_failed(Calyx::Misc::NameUtils.valid_name?(username), "Username is not valid: #{username}"){
            send_data [11].pack("C")
          }
 
          LOG.debug "Username: #{username}"

          # Set up cipher
          session_key = client_key + server_key
          session_key.collect {|k| k.int }
          in_cipher = ISAAC.new(session_key)
          out_cipher = ISAAC.new(session_key.collect {|i| i + 50 })
          
          @session = Session.new(self, username, password, uid, in_cipher, out_cipher)
          @state = :authenticated
          
          WORLD.add_to_login_queue(@session)
        end
      when :authenticated
        if @popcode == -1
          if @buffer.length >= 1
            opcode = @buffer.read_byte
            random = @session.in_cipher.next_value.ubyte
            @popcode = (opcode - random).ubyte
            @psize = PACKET_SIZES[@popcode]
          else
            return
          end
        end

        if @psize == -1
          if @buffer.length >= 1
            @psize = @buffer.read_byte
          else
            return
          end
        end

        if @buffer.length >= @psize
          payload = @buffer.slice!(0...@psize)
          process_packet Packet.new(@popcode, :fixed, payload)
          @popcode = -1
          @psize = -1
        end
      end
      
      process_buffer(lim + 1) if @buffer.length > 0
    end
    
    def process_packet(packet)
      return if packet.opcode == 0
      
      WORLD.submit_task {
        begin
          Calyx::Net.handle_packet(@session.player, packet)
        rescue Exception => e
          LOG.error "Error processing packet"
          LOG.error e
        end
      }
    end
    
    # Evaluates the expression, and if false prints out the given message and executes the block.
    # Additionally, the connection will be closed if false, and only after writing if a block exists.
    def check_failed(exp, msg, &blk)
      unless exp
        LOG.error msg
        blk and yield blk
        close_connection blk != nil
      end
      !exp
    end
    
    # Called when the connection has been closed.
    def unbind
      LOG.info "Connection closed"
      
      if CONNECTION_COUNTS.include?(@ip)
        count = CONNECTION_COUNTS[@ip]
        count -= 1
        
        if count <= 0
          CONNECTION_COUNTS.delete @ip
        else
          CONNECTION_COUNTS[@ip] = count
        end
      end
      
      if @session != nil && @session.player != nil
        WORLD.submit_task {
          WORLD.unregister(@session.player)
        }
      end
    end
  end
end
