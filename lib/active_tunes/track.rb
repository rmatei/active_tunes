module ActiveTunes
  class Track < ActiveMac::Object
    
    TEXT_FIELDS = [:artist, :album_artist, :name, :album, :genre]
    attr_accessor :tries
    
    # Current selection in iTunes
    def self.selection
      ActiveMac::App.find("iTunes").selection.map { |object| new(object.reference) }
    end
    
    # Top-level tagging function
    def tag
      self.tries = 1
      begin
        process_untagged if artist.blank? and album.blank?
        clean_text_fields
        set_genres
        set_album
        tag_album
        # mark_as_tagged
        # printf("%-20s  -  %-30s  |  %s\n", artist.first(20), name.first(30), grouping.first(110))
        log "tagged"
      rescue
        if self.tries < 4
          sleep 3
          puts "Retrying..."
          self.tries += 1
          retry
        else
          raise
        end
      end
    end
    
    
    
    # STANDARD TAGGING OPERATIONS (applied to all files)
    
    def process_untagged
      return unless name.include? " - "
      self.artist = self.name.split(" - ").first
      self.name = self.name.split(" - ").last
    end
    
    def clean_text_fields
      TEXT_FIELDS.each do |field|
        value = self.send(field)
        value.gsub!('Feat.', 'feat.')
        self.send("#{field}=", value)
      end
    end
    
    def set_genres
      if tags.empty?
        self.grouping = genre.downcase.strip.gsub(' ', '-')
      else
        self.grouping = tags.map {|t| t.gsub(' ', '-')}.join(' ')
      end
      self.genre = tags.first.titleize if self.genre.blank?
    end
    
    def set_album
      self.album = name if album.blank? and mix_length?
      # self.album_artist = artist if album_artist.blank? and !album.blank? and !compilation
    end
    
    def tag_album
      ActiveTunes::Album.processed_albums ||= []
      unless ActiveTunes::Album.processed_albums.include? self.album
        full_album.tag
        ActiveTunes::Album.processed_albums << self.album
      end
    end
    
    
    
    # SPECIAL TAGGING OPERATIONS
    
    def set_as_mix
      self.gapless = true
      self.compilation = true
      self.category = "Mix"
      self.album = name if album.blank? and mix_length?
    end
    
    def set_as_single_track
      return false if mix_length?
      self.category = "Single tracks"
      # self.album = "Single tracks"
      # self.album_artist = ""
      # self.track_number = ""
      # self.track_count = ""
      # self.compilation = true
    end
    
    def mark_as_tagged
      text = "Tagged by ActiveTunes v#{ActiveTunes::VERSION}"
      unless comment.include? text
        self.comment = (comment + text)
      end
    end
    
    def capitalize
      TEXT_FIELDS.each do |field|
        self.send("#{field}=", self.send(field).titleize)
      end
    end
    
    
    
    # HELPERS
  
    def full_album
      ActiveTunes::Album.new(album_tracks.map { |object| ActiveTunes::Track.new(object) })
    end
    
    def album_tracks
      if !album_artist.blank?
        Appscript.app("iTunes.app").user_playlists["Music"].tracks[Appscript.its.album.eq(album).and(whose.album_artist.eq(album_artist))].get
      elsif compilation
        Appscript.app("iTunes.app").user_playlists["Music"].tracks[Appscript.its.album.eq(album)].get
      else
        Appscript.app("iTunes.app").user_playlists["Music"].tracks[Appscript.its.album.eq(album).and(whose.artist.eq(artist))].get
      end
    end
    
    # Album artist if it exists, otherwise track artist
    def combined_artist
      album_artist.blank? ? artist : album_artist
    end
    
    # From last.fm
    def tags
      @tags ||= TagList.new(combined_artist).tags
    end
    
    # True if longer than 30 minutes
    def mix_length?
      length = time.split(':').map { |t| t.to_i }
      (length.size == 3 or (length.size == 2 and length.first > 30))
    rescue Exception => e
      puts e.message
      false
    end
    
    def has_art?
      !self.reference.artworks.get.empty?
    end
    
    def log(action = "")
      size = 30
      puts "#{artist.ljust(30).first(30)}  -  #{name.ljust(30).first(30)}  =>  #{action}"
    end
  
  end
end