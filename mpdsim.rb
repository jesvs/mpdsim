#!/usr/bin/env ruby

require 'yaml'
require 'optparse'
require "bundler"
require 'lastfm'
require 'ruby-mpd'

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
  options[:duplicates]  = config['duplicates'] || false

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

  opts.on("-d", "--[no-]duplicates", "Keep duplicates") do |d|
    options[:duplicates] = d
  end

  opts.on("-s", "--[no-]shuffle", "Shuffle results") do |n|
    options[:shuffle] = n
  end

  opts.on("-n", "--random", "Similar tracks from a random track from the database") do |n|
    options[:random] = n
  end

  opts.on("-q", "--quiet", "Quiet, no ouput") do |q|
    options[:quiet] = q
  end

  opts.on("-v", "--verbose", "Be verbose, shows added tracks") do |v|
    options[:verbose] = v
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!
quiet   = options[:quiet]
verbose = options[:verbose]

lastfm = Lastfm.new config['api_key'], config['api_secret']
mpd    = MPD.new config['mpd_host'], config['mpd_port']

begin
  mpd.connect
rescue
  print "Could not connect to MPD server."
  exit 1
end

if options[:random]
  files = mpd.send_command 'list file'
  file = files[rand(0...files.size)]
  song = mpd.where(file: file).first
  options[:artist] = song.artist
  options[:track] = song.title
end

begin
  # Build query from currently playing song or options
  if options[:artist].nil? || options[:track].nil?
    current_song = mpd.current_song
    query = { artist: current_song.artist, track: current_song.title }
  else
    query = { artist: options[:artist], track: options[:track] }
  end
rescue NoMethodError
  puts "Error: You must specify artist and title"
  exit 1
end

query[:limit]       = options[:limit] || 10
query[:autocorrect] = options[:autocorrect] || true

unless quiet
  puts "Getting #{query[:limit]} similar tracks to #{query[:artist]} - #{query[:track]}"
end

similar = lastfm.track.get_similar(query)

similar_tracks = []
if !similar.is_a? Array
  puts "Nothing found"
  exit 0
end
similar.each do |track|
  artist  = track['artist']['name']
  title   = track['name']
  begin
    results = mpd.where( artist: artist, title: title )
  rescue
    puts $!
  end
  if !results.nil? && !results.empty?
    if options[:duplicates]
      similar_tracks << results
    else
      if options[:shuffle]
        similar_tracks << results[rand(0...results.size)]
      else
        similar_tracks << results.first
      end
    end
  end
end

similar_tracks.flatten!
similar_tracks.shuffle! if options[:shuffle]
mpd.clear if options[:replace]

puts "#{similar_tracks.size} tracks added from database." unless quiet

# print found tracks
if verbose
  similar_tracks.each do |t|
    puts "#{t.artist} - #{t.title}"
  end
end

# create playlist
if options[:playlist]
  playlist = MPD::Playlist.new(mpd, "Similar to #{query[:artist]} - #{query[:track]}")
  
  # add requested track to playlist
  results = mpd.where(artist: query[:artist], title: query[:track])
  if options[:shuffle]
    playlist.add results[rand(0...results.size)]
  else
    playlist.add results.first
  end

  # add found tracks
  similar_tracks.each do |track|
    playlist.add track
  end
  playlist.load if options[:load]
else
  # add requested song to queue
  results = mpd.where(artist: query[:artist], title: query[:track])
  if options[:duplicates]
    if options[:shuffle]
      mpd.add results[rand(0...results.size)]
    else
      mpd.add results
    end
  else
    mpd.add results[rand(0...results.size)]
  end

  similar_tracks.each do |track|
    mpd.add track
  end
end
mpd.disconnect
