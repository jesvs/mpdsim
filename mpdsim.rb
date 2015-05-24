#!/usr/bin/env ruby

require 'yaml'
require 'optparse'
require "bundler"
Bundler.require

config = YAML.load_file(File.join(File.expand_path('~'), '.config', 'mpdsim.conf'))['mpdsim']

# Options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  options[:limit]       = config['limit'] || 50
  options[:playlist]    = config['playlist'] || true
  options[:replace]     = config['replace'] || false
  options[:autocorrect] = config['autocorrect'].to_i || 1
  options[:load]        = config['load'] || true

  opts.on("-aNAME", "--artist=NAME", "Artist name") do |a|
    options[:artist] = a
  end

  opts.on("-tTITLE", "--track=NAME", "Track name") do |t|
    options[:track] = t
  end

  opts.on("-lN", "--limit=N", "Limit search to N results (default #{options[:limit]})") do |l|
    options[:limit] = l
  end

  opts.on("-p", "--[no-]playlist", "Create playlist") do |p|
    options[:playlist] = p
  end

  opts.on("-r", "--replace", "Replace current queue") do |r|
    options[:replace] = r
  end

  opts.on("-c", "--[no-]autocorrect", "Transform misspelled artist and track names into corrent one.") do |c|
    options[:autocorrect] = 1 if c
  end

  opts.on("-o", "--[no-]loadplaylist", "Load playlist into current queue") do |o|
    options[:load] = o
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

# Last FM
lastfm = Lastfm.new config['api_key'], config['api_secret']

# MPD
mpd = MPD.new config['mpd_host'], config['mpd_port']

mpd.connect
begin
  if options[:artist].nil? && options[:track].nil?
    current_song = mpd.current_song
    song = { artist: current_song.artist, track: current_song.title }
  else
    song = { artist: options[:artist], track: options[:track] }
  end
rescue NoMethodError
  puts "You must specify artist and title"
  exit 1
end
song[:limit] = options[:limit] || 10
song[:autocorrect] = options[:autocorrect] || true

similar = lastfm.track.get_similar(song)

similar_tracks = []
begin
  similar.each do |track|
    artist  = track['artist']['name']
    title   = track['name']
    results = mpd.where( artist: artist, title: title )
    similar_tracks << results.first unless results.empty?
  end
rescue NoMethodError
  puts "Nothing found!"
  exit 1
end
similar_tracks.flatten!
mpd.clear if options[:replace]

# create playlist
if options[:playlist]
  playlist = MPD::Playlist.new(mpd, "Similar to #{song[:artist]} - #{song[:track]}")
  # add requested song to playlist
  playlist.add mpd.where(artist: song[:artist], title: song[:track]).first
  similar_tracks.each do |track|
    playlist.add track
  end
  playlist.load if options[:load]
else
  similar_tracks.each do |track|
    mpd.add track
  end
end
