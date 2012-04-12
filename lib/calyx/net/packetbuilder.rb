module Calyx::Net
  class PacketBuilder
    # Bit masks for bit packing
    BIT_MASK_OUT = (0...32).collect {|i| (1 << i) - 1 }
    
    # The opcode for this packet
    attr :opcode
     
    # The packet type. Fixed, Variable or Variable Short
    attr :type
     
    # The buffer for this packet
    attr :buffer
    
    # The current bit position
    attr :bit_position
    
    def initialize(opcode = -1, type = :FIXED)
      @opcode = opcode
      @type = type
      @buffer = ""
    end
    
    # Adds a byte to the array.
    def add_byte(val)
      @buffer << [val].pack("C")
      self
    end
    
    # Adds multiple bytes to the array.
    def add_bytes(val)
      @buffer << val
      self
    end
    
    # Adds a byte type a to the array.
    def add_byte_a(val)
      add_byte (val + 128)
      self
    end
    
    # Adds a byte type c to the array.
    def add_byte_c(val)
      add_byte -val
      self
    end
    
    # Adds a byte type s to the array.
    def add_byte_s(val)
      add_byte (128 - val)
      self
    end
    
    # Adds a short to the array.
    def add_short(val)
      @buffer << [val].pack("n")
      self
    end
    
    # Adds an int to the array.
    def add_int(val)
      add_byte (val >> 24).byte
      add_byte (val >> 16).byte
      add_byte (val >> 8).byte
      add_byte val.byte
      self
    end
    
    # Adds a long to the array.
    def add_long(val)
      add_byte (val >> 56).int
			add_byte (val >> 48).int
			add_byte (val >> 40).int
			add_byte (val >> 32).int
			add_byte (val >> 24).int
			add_byte (val >> 16).int
			add_byte (val >> 8).int
			add_byte val.int
      self
    end
    
    # Adds a string to the array.
    def add_str(val)
      @buffer << (val + "\n")
      self
    end
    
    # Adds a short type a to the array.
    def add_short_a(val)
      add_byte (val >> 8)
      add_byte (val + 128)
      self
    end
    
    # Adds a little-endian short to the array.
    def add_leshort(val)
      add_byte val
      add_byte (val >> 8)
      self
    end
    
    # Adds a little-endian short type a to the array.
    def add_leshort_a(val)
      add_byte (val + 128)
      add_byte (val >> 8)
      self
    end
    
    def start_bit_access
      @bit_position = @buffer.size * 8
      self
    end
    
    def finish_bit_access
      @bit_position = (@bit_position + 7) / 8
      self
    end
    
    # Adds a series of bits to the array.
    def add_bits(num, val)
      byte_pos = @bit_position >> 3
      bit_offset = 8 - (@bit_position & 7)
      @bit_position += num
      
      while num > bit_offset
        @buffer[byte_pos] = [0].pack("c") if @buffer[byte_pos] == nil
        @buffer[byte_pos] = [(@buffer[byte_pos].unpack("c")[0] & ~BIT_MASK_OUT[bit_offset])].pack("c")
        @buffer[byte_pos] = [(@buffer[byte_pos].unpack("c")[0] | (val >> (num - bit_offset)) & BIT_MASK_OUT[bit_offset])].pack("c")
        byte_pos += 1
        num -= bit_offset
        bit_offset = 8
      end
      
      @buffer[byte_pos] = [0].pack("c") if @buffer[byte_pos] == nil
      
      if num == bit_offset
        @buffer[byte_pos] = [(@buffer[byte_pos].unpack("c")[0] & ~BIT_MASK_OUT[bit_offset])].pack("c")
        @buffer[byte_pos] = [(@buffer[byte_pos].unpack("c")[0] | (val & BIT_MASK_OUT[bit_offset]))].pack("c")
      else
        @buffer[byte_pos] = [(@buffer[byte_pos].unpack("c")[0] & ~(BIT_MASK_OUT[num] << (bit_offset - num)))].pack("c")
        @buffer[byte_pos] = [(@buffer[byte_pos].unpack("c")[0] | ((val & BIT_MASK_OUT[num]) << (bit_offset - num)))].pack("c")
      end
      
      self
    end
    
    # Adds an integer type 1 to the array.
    def add_int1(val)
      add_byte val >> 8
      add_byte val
      add_byte val >> 24
      add_byte val >> 16
      self
    end
    
    # Adds an integer type 2 to the array.
    def add_int2(val)
      add_byte val >> 16
      add_byte val >> 24
      add_byte val
      add_byte val >> 8
      self
    end
    
    # Adds a little-endian integer to the array.
    def add_leint(val)
      add_byte val
      add_byte val >> 8
      add_byte val >> 16
      add_byte val >> 24
      self
    end
    
    # Adds a series of bytes into the array.
    def add_bytes_range(data, offset, length)
      @buffer << data[offset...offset+length].pack("c" * length)
      self
    end
    
    # Adds a series of type a bytes into the array.
    def add_reverse_a(data, offset, length)
      bytes = data[offset...offset+length].reverse.unpack("c" * length)
      bytes.each {|e| add_byte_a(e) }
      self
    end
    
    # Adds a series of reversed bytes into the array.
    def add_reverse(is, offset, length)
      @buffer << data[offset...offset+length].reverse
      self
    end
    
    # Adds a three byte integer into the array.
    def add_tribyte(val)
      add_byte val >> 16
      add_byte val >> 8
      add_byte val
      self
    end
    
    # Adds an smart into the array.
    def add_smart(val)
      val >= 128 ? add_short(val + 32768) : add_byte(val)
      self
    end
    
    # Adds an unsigned smart into the array.
    def add_usmart(val)
      if val >= 128 
        add_short(val + 49152)
      else 
        add_byte(val + 64)
      end
      
      self
    end
    
    # Checks whether or not the buffer has data in it.
    def empty?
      @buffer.empty?
    end
    
    # Creates the packet.
    def to_packet
      Packet.new @opcode, @type, @buffer
    end
  end
end
