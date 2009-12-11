module ActiveTunes
  class Album < Array
    
    cattr_accessor :processed_albums
    
    # Top-level tagging function
    def tag
      self.album_artist = nil if same_artist?
      self.compilation = true unless same_artist?
      log "tagged"
    end
    
    # Fix for split album art view in iTunes
    def merge_view
      original = compilation
      opposite = original ? false : true
      self.compilation = opposite
      self.compilation = original
    end
    
    # Shared values - identical across all tracks
    [:compilation, :album, :album_artist].each do |field|
      define_method field do 
        first.send(field)
      end
      
      define_method "#{field}=".intern do |value|
        each { |track| track.send("#{field}=".intern, value) }
      end
    end
    
    
    # HELPERS
    
    def artist
      if size == 1 or !album_artist.blank? or !compilation
        first.combined_artist
      else
        nil
      end
    end
    
    def same_artist?
      result = true
      each { |track| result = false if track.artist != first.artist }
      return result
    end
    
    def log(action = "")
      size = 30
      puts "ALBUM: #{artist.ljust(23).first(23)}  -  #{album.ljust(30).first(30)}  =>  #{action}"
    end
    
  end
end