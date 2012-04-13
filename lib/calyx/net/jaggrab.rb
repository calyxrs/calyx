module Calyx::Net
  class JaggrabConnection < EM::Connection
    include EM::P::LineText2
    
    PATHS = {
      /\.pack200$/    => "runescape.pack200",
      /\.js5$/        => "runescape.js5",
      /\.pack$/       => "unpackclass.pack",
      /^crc/          => "crc",
      /^config/       => "config",
      /^title/        => "title",
      /^interface/    => "interface",
      /^media/        => "media",
      /^sounds/       => "sounds",
      /^textures/     => "textures",
      /^versionlist/  => "versionlist",
      /^wordenc/      => "wordenc"
    }

    INDEX = {
      "title" => 1,
      "config" => 2,
      "interface" => 3,
      "media" => 4,
      "versionlist" => 5,
      "textures" => 6,
      "wordenc" => 7,
      "sounds" => 8
    }
    
    LOG = Logging.logger['cache']
    
    def receive_line(line)
      line = line.strip
      
      if line =~ /^JAGGRAB \/(.*)$/
        path = fix_path($1)
        
        LOG.debug "serving '#{path}' via JAGGRAB"
        
        if INDEX.include?(path)
          ind = INDEX[path]
          
          send_data $cache.get(0, ind)
        end
      end
    end
    
    def fix_path(path)
      match = PATHS.find {|k, v| path =~ k }
      match ? match[1] : path
    end
  end
end
