module ActiveTunes
  class TagList
    
    attr_accessor :tags
    cattr_accessor :cached_results
    
    def self.get(artist)
      # debug
        tag_list.map! { |tag| tag.name.downcase.gsub(' ', '-') }
        tag_list = tag_list.delete_if {|tag| tag.include? artist.strip.downcase.gsub(' ', '-')}
        tag_list = tag_list.uniq.first(20)
      # end
    end
    
    def initialize(artist)
      @artist = artist.strip.gsub(/\//, ' ').gsub(/ & /, ' and ').gsub(/\ +/, ' ')
      if artist.blank?
        self.tags = []
      else
        get_tags
        delete_bad_tags
      end
    end
    
    private
    
    def get_tags
      self.tags = get_tags_from_api.delete_if {|tag| tag.count.to_i < 10}.map { |tag| tag.name.strip }
    end
    
    def get_tags_from_api
      self.class.cached_results ||= {}
      if self.class.cached_results[@artist]
        self.class.cached_results[@artist]
      else
        self.class.cached_results[@artist] = Scrobbler::Artist.new(@artist).top_tags
      end
    end
    
    def delete_bad_tags
      self.tags = tags.delete_if {|tag| tag.downcase.include?(@artist.strip.downcase)}
    end
    
  end
end