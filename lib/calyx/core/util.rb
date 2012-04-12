class Integer
  def overflow(i, e = 2 ** 31)
    f = (Math.log(e) / Math.log(2)).to_i+1
    g = (2 ** f) - 1
         
    if i < -e
      i & g
    elsif i > e - 1
      -(-(i) & g)
    else 
      i
    end
  end
  
  def nibble
    overflow(self.to_i & 0xf, 2 ** 4)
  end
 
  def byte
    overflow(self.to_i, 2 ** 7)
  end
   
  def ubyte
    overflow(self.to_i & 0xff, 2 ** 8)
  end
   
  def short
    overflow(self.to_i, 2 ** 15)
  end
   
  def ushort
    overflow(self.to_i & 0xffff, 2 ** 16)
  end
   
  def int
    overflow(self.to_i, 2 ** 31)
  end
   
  def uint
    overflow(self.to_i & 0xffffffff, 2 ** 32)
  end
   
  def long
    overflow(self.to_i, 2 ** 64)
  end
   
  def ulong
    overflow(self.to_i & 0xffffffffffffffff, 2 ** 64)
  end
end

module Calyx::Misc
  class AutoHash < Hash
    def initialize(*args)
      super()
      @update, @update_index = args[0][:update], args[0][:update_key] unless args.empty?
    end

    def [](k)
      if self.has_key?k
        super(k)
      else
        AutoHash.new(:update => self, :update_key => k)
      end
    end

    def []=(k, v)
      @update[@update_index] = self if @update and @update_index
      super
    end
  end
  
  class HashWrapper
    def initialize(attributes)
      @attributes = attributes
    end

    def method_missing(name, *args, &blk)
      if args.empty? && blk.nil? && @attributes.has_key?(name)
        @attributes[name]
      else
        nil
      end
    end
  end

  # Update flags
  class Flags
    attr :flags
    
    def initialize
      @flags = {}
      @flags.default = false
    end
    
    def flag(flag)
      @flags[flag] = true
    end
    
    def set(flag, value)
      @flags[flag] = value
    end
    
    def get(flag)
      @flags[flag]
    end
    
    def reset
      @flags.clear
    end
    
    def update_required?
      @flags.has_value?(true)
    end
  end
  
  class TextUtils
    XLATE_TABLE = [
      ' ', 'e', 't', 'a', 'o', 'i', 'h', 'n', 's', 'r', 'd', 'l', 'u',
      'm', 'w', 'c', 'y', 'f', 'g', 'p', 'b', 'v', 'k', 'x', 'j', 'q',
      'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '!',
      '?', '.', ',', ':', ';', '(', ')', '-', '&', '*', '\\', '\'', '@',
      '#', '+', '=', '\243', '$', '%', '"',	'[', ']'
    ]
    
    def TextUtils.unpack(data, size)
      decode = Array.new(4096, 0)
      idx = 0
      high = -1
      
      (0...(size * 2)).each {|i|
        val = (data[i / 2] >> (4 - 4 * (i % 2))).nibble
        
        if high == -1
          if val < 13
            decode[idx] = XLATE_TABLE[val].bytes.first.byte
            idx += 1
          else
            high = val
          end
        else
          decode[idx] = XLATE_TABLE[((high << 4) + val) - 195].bytes.first.byte
          high = -1
          idx += 1
        end
      }
      
      decode[0...idx].pack("C" * idx)
    end
    
    def TextUtils.optimize(str)
      end_marker = true
      
      (0...str.length).each {|i|
        if end_marker && str[i].chr >= 'a' && str[i].chr <= 'z'
          str[i] = (str[i].bytes.first - 0x20).chr
          end_marker = false
        end
        
        if str[i].chr == "." || str[i].chr == "!" || str[i].chr == "?"
          end_marker = true
        end
      }
      
      str
    end
    
    def TextUtils.filter(str)
      valid = str.unpack("C" * str.size).find_all {|c| XLATE_TABLE.include?(c.chr) }
      valid.pack("C" * valid.size)
    end
    
    def TextUtils.pack(size, text)
      data = Array.new(size, 0)
      text = text[0...80] if text.size > 80
      text = text.downcase
      carry = -1
      offset = 0
      
      (0...text.size).each {|i|
        table_idx = XLATE_TABLE.find_index {|e| e == text[i].chr} || 0
        table_idx += 195 if table_idx > 12
        
        if carry == -1
          if table_idx < 13
            carry = table_idx
          else
            data[offset] = table_idx.byte
            offset += 1
          end
        elsif table_idx < 13
          data[offset] = ((carry << 4) + table_idx).byte
          carry = -1
          offset += 1
        else
          data[offset] = ((carry << 4) + (table_idx >> 4)).byte
          carry = table_idx.nibble
          offset += 1
        end
      }
      
      if carry != -1
        data[offset] = (carry << 4).byte
        offset += 1
      end
      
      data
    end
    
    def TextUtils.repack(size, packet)
      raw_data = packet.read_bytes(size).unpack("C" * size)
      chat_data = (0...size).collect {|i| (raw_data[size - i - 1] - 128).byte }
      unpacked = TextUtils.unpack(chat_data, size)
      unpacked = TextUtils.filter(unpacked)
      unpacked = TextUtils.optimize(unpacked)
      TextUtils.pack(size, unpacked)
    end
  end
  
  # Provides utility methods for converting and validating player usernames.
  class NameUtils
    VALID_CHARS = [
      '_', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
      'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y',
      'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '!', '@',
      '#', '$', '%', '^', '&', '*', '(', ')', '-', '+', '=', ':', ';',
      '.', '>', '<', ',', '"', '[', ']', '|', '?', '/', '`'
    ]
  
    # Fixes capitalization in the username.
    def NameUtils.fix_name(str)
      return str if str.length < 1
      
      (0...str.length).each {|i|
        if str[i].chr == "_"
          str[i] = " " 
          if i+1 < str.length && str[i+1].chr >= 'a' && str[i+1].chr <= 'z'
            str[i+1] = ((str[i+1].bytes.first + 65) - 97).chr
          end
        end
      }
      
      if str[0].chr >= 'a' && str[0].chr <= 'z'
        str[0] = ((str[0].bytes.first + 65) - 97).chr
      end
      
      str
    end
  
    # Formats the username for display.
    def NameUtils.format_name(str)
      NameUtils.fix_name str.gsub(" ", "_")
    end
  
    # Formats the username for protocol usage.
    def NameUtils.format_name_protocol(str)
      str.downcase.gsub(" ", "_")
    end
  
    # Checks whether the username follows the protocol format.
    def NameUtils.valid_name?(str)
      NameUtils.format_name_protocol(str) =~ /^[a-z0-9_]+$/
    end
  
    # Converts the username into a 64 bit integer.
    def NameUtils.name_to_long(name)
      l = 0
      
      (0...name.length).each {|i|
        c = name[i].chr
        l *= 37
        l += (1  + name[i].bytes.first) - 65 if c >= 'A' and c <= 'Z'
        l += (1  + name[i].bytes.first) - 97 if c >= 'a' and c <= 'z'
        l += (27 + name[i].bytes.first) - 48 if c >= '0' and c <= '9'
      }
      
      while l % 37 == 0 && l != 0
        l /= 37
      end
      
      l
    end
  
    # Converts the 64 bit integer version of the username into a string.
    def NameUtils.long_to_name(n)
      n = n.long
      str = ""
      i = 0
      while n != 0
        k = n.long
        n = (n / 37).long
        str << VALID_CHARS[(k-n*37).int]
        i = i+1
      end
      
      str.reverse
    end
  end
  
  class ThreadPool
    class Executor
      attr_reader :active
      
      def initialize(queue, mutex)
        @thread = Thread.new do
          loop do
            mutex.synchronize { @tuple = queue.shift }
            if @tuple
              args, block = @tuple
              @active = true
              begin
                block.call(*args)
              rescue Exception => e
                log = Logging.logger['exec']
                log.error "Threadpool error"
                log.error e
              end
              block.complete = true
            else
              @active = false
              sleep 0.01

            end
          end
        end
      end

      def close
        @thread.exit
      end
    end

    attr_accessor :queue_limit


    # Initialize with number of threads to run
    def initialize(count, queue_limit = 0)
      @mutex = Mutex.new
      @executors = []
      @queue = []
      @queue_limit = queue_limit
      @count = count
      count.times { @executors << Executor.new(@queue, @mutex) }
    end

    # Runs the block at some time in the near future
    def execute(*args, &block)
      init_completable(block)

      if @queue_limit > 0
        sleep 0.01 until @queue.size < @queue_limit
      end

      @mutex.synchronize do
        @queue << [args, block]
      end
    end

    # Runs the block at some time in the near future, and blocks until complete
    def synchronous_execute(*args, &block)
      execute(*args, &block)
      sleep 0.01 until block.complete?
    end

    # Size of the task queue
    def waiting
      @queue.size
    end

    # Size of the thread pool
    def size
      @count
    end

    # Kills all threads
    def close
      @executors.each {|e| e.close }
    end

    # Sleeps and blocks until the task queue is finished executing
    def join
      sleep 0.01 until @queue.empty? && @executors.all?{|e| !e.active}
    end
    
    def busy
      !(@queue.empty? && @executors.all?{|e| !e.active})
    end

    protected
    
    def init_completable(block)
      block.extend(Completable)
      block.complete = false
    end

    module Completable
      def complete=(val)
        @complete = val
      end

      def complete?
        !!@complete
      end
    end
  end
end
