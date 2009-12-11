$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# require 'active_mac'
require 'scrobbler'
Dir["#{File.dirname(__FILE__)}/active_tunes/*.rb"].sort.each { |lib| require lib }

module ActiveTunes
  VERSION = '0.0.1'
end

def its
  ActiveTunes::Track.selection
end

def itt
  ActiveTunes::Track.selection.first
end