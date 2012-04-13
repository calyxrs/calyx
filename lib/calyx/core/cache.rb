module Calyx::Misc
  class Cache
    INDEX_SIZE = 6
    DATA_BLOCK_SIZE = 512
    DATA_HEADER_SIZE = 8
    DATA_SIZE = DATA_BLOCK_SIZE + DATA_HEADER_SIZE
    
    def initialize(path)
      # Find how many index files exist
      count = 0.upto(255).each do |i|
        break i unless FileTest.exists?(file_path("main_file_cache.idx#{i}", path))
      end
      
      # Make sure the user has added the cache files
      raise "Cache files not installed! Please place them in the 'data/cache' directory" if count == 0
      
      # Gather file objects
      @data_file = File.open(file_path("main_file_cache.dat", path), "r")
      @index_files = []
      
      count.times do |i|
        @index_files << File.open(file_path("main_file_cache.idx#{i}", path), "r")
      end
    end
    
    def get(cache, file)
      # then convert crc table stuff (easy with array pack)
      # then make server send data back to the client
      
      index_file = @index_files[cache]
      cache += 1
      
      index = IO.read(index_file.path, INDEX_SIZE, INDEX_SIZE * file).unpack("c" * 6)
      file_size  = (index[0].ubyte << 16) | (index[1].ubyte << 8) | index[2].ubyte;
      file_block = (index[3].ubyte << 16) | (index[4].ubyte << 8) | index[5].ubyte;
      
      remaining_bytes = file_size
      current_block = file_block
      buffer = ""
      cycles = 0
      
      while remaining_bytes > 0
        size = DATA_SIZE
        rem = @data_file.size - current_block * DATA_SIZE
        size = rem if rem < DATA_SIZE
        
        header = IO.read(@data_file.path, DATA_HEADER_SIZE, current_block * DATA_SIZE).unpack("nncccc")
        
        next_file_id = header[0]
        current_part_id = header[1]
        next_block_id = (header[2].ubyte << 16) | (header[3].ubyte << 8) | header[4].ubyte
        next_cache_id = header[5].ubyte
        
        size -= 8
        
        cycle_bytes = remaining_bytes > DATA_BLOCK_SIZE ? DATA_BLOCK_SIZE : remaining_bytes
        
        buffer << IO.read(@data_file.path, cycle_bytes, current_block * DATA_SIZE + DATA_HEADER_SIZE)

        remaining_bytes -= cycle_bytes

        raise "Cycle does not match part id." if cycles != current_part_id

        if remaining_bytes > 0
          raise "Unexpected next cache id." if next_cache_id != cache
          raise "Unexpected next file id." if next_file_id != file
        end

        cycles += 1
        current_block = next_block_id
      end
      
      buffer
    end
    
    def close
      @data_file.close
      @index_files.each {|file| file.close }
    end
    
    def cache_count
      @index_files.size
    end
    
    def file_count(cache)
      (@index_files[cache].size / INDEX_SIZE) - 1
    end
    
    private
    
    def file_path(file, path)
      File.join(path, file)
    end
  end
end
