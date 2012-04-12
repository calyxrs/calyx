module Calyx::Net
  class Packet
    # The opcode for this packet
    attr :opcode
    
    # The packet type. Fixed, Variable or Variable Short
    attr :type
    
    # The buffer for this packet
    attr_reader :buffer
    
    def initialize(opcode, type, buffer)
      @opcode = opcode
      @type = type
      @buffer = buffer
    end
    
    # Is the packet raw data
    def is_raw
      opcode == -1
    end
    
    # Reads a byte from the array, and seeks forward.
    def read_byte
      val = @buffer.unpack("c").first
      @buffer.slice!(0...1)
      val
    end
    
    # Reads several bytes from the array, and seeks forward.
    def read_bytes(size)
      @buffer.slice!(0...size)
    end
    
    # Reads an unsigned byte from the array, and seeks forward.
    def read_ubyte
      read_byte.ubyte
    end
    
    # Reads a short from the array, and seeks forward.
    def read_short
      val = @buffer.unpack("n").first
      @buffer.slice!(0...2)
      val
    end
    
    # Reads a short from the array, and seeks forward.
    def read_ushort
      val = @buffer.unpack("S").first
      @buffer.slice!(0...2)
      val
    end
    
    # Reads an int from the array, and seeks forward.
    def read_int
      (read_ubyte << 24) + (read_ubyte << 16) + (read_ubyte << 8) + read_ubyte
    end
  
    # Reads a long from the array, and seeks forward.
    def read_long
      l = (read_int & 0xffffffff).long
      l1 = (read_int & 0xffffffff).long
      return ((l << 32) + l1).long
    end
    
    # Reads byte type c from the array, and seeks forward.
    def read_byte_c
      (-read_byte).byte
    end
    
    # Reads byte type s from the array, and seeks forward.
    def read_byte_s
      (128 - read_byte).byte
    end
    
    # Reads a byte type a, and seeks forward.
    def read_byte_a
      (read_byte - 128).byte
    end
    
    # Reads a little-endian short from the array, and seeks forward.
    def read_leshort
      i = read_ubyte | (read_ubyte << 8)
      
		  if i > 32767
			  i -= 0x10000
      end
			
		  i.short
    end

    # Reads a short type a from the array, and seeks forward.
    def read_short_a
      i = (read_ubyte << 8) | (read_byte - 128).ubyte

		  if i > 32767
			  i -= 0x10000
      end
			
		  i.short
    end

    # Reads a little-endian short type a from the array, and seeks forward.
    def read_leshort_a
      i = (read_byte - 128).ubyte | (read_ubyte << 8)
      
		  if i > 32767
			  i -= 0x10000
      end
			
		  i.short
    end
    
    # Reads a V1 integer.
    def read_int1

    end
    
    # Reads a V2 integer.
    def read_int2

    end
    
    # Reads a three byte integer, and seeks forward.
    def read_tribyte
      
    end
    
    # Reads a string from the array, and seeks forward.
    def read_str(terminator = 10)
      str = ""
      while @buffer.length > 0 and (b = @buffer.unpack("C").first) != terminator
        str << b.chr
        @buffer.slice!(0...1)
      end
      @buffer.slice!(0...1)
      str
    end
    
    # Reads a series of bytes in reverse, and seeks forward.
    def read_reverse(is, offset, length)
      
    end
    
    # Reads a series of bytes type a in reverse, and seeks forward.
    def read_reverse_a(is, offset, length)
      
    end
    
    # Reads a series of bytes
    def read(is, offset, length)
      (0...length).each {|e|
        is[offset + e] = read_byte
      }
    end
    
    # Reads a smart
    def read_smart
      
    end
    
    # Reads an unsigned smart
    def read_usmart
      
    end
    
    def <<(data)
      @buffer << data
    end
    
    def empty?
      @buffer.empty?
    end
    
    def length
      @buffer.length
    end
    
    def size
      @buffer.size
    end
    
    def slice!(range)
      @buffer.slice!(range)
    end
  end
end
