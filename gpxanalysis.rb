#!/usr/bin/ruby

require 'rexml/document'
require 'rexml/streamlistener'
require 'distance'

def openBzip(filename)
  bzip2 = IO.popen("bzip2 -dc #{filename}","r")
  content = bzip2.read
  bzip2.close
  return content
end

#Convert a gpx timestamp into a native time
def parseTime(timeString)
  timeStringParts = timeString.scan(/([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2}).*Z/)[0]
  Time.utc(timeStringParts[0], timeStringParts[1], timeStringParts[2], timeStringParts[3], timeStringParts[4], timeStringParts[5])
end

class GPXListener
  attr_reader :trksegs
  include REXML::StreamListener
  def scan(xml)
    @trksegs        = []
    @current_trkseg = nil
    @in_trkpt       = false
    @in_ele         = false
    @in_time        = false
    REXML::Document::parse_stream(xml, self)
  end
  def tag_start(name, attrs)
    case name
    when "trkseg"
#      puts "found trkseg"
      @current_trkseg = []
    when "trkpt"
      lat = attrs["lat"]
      lon = attrs["lon"]
#      puts "Found #{lat} #{lon}"
      @in_trkpt = true
      @trkpt = Entry.new
      @trkpt.lat = lat.to_f
      @trkpt.lon = lon.to_f
    when "ele"
      if !@in_trkpt
        puts "Found an elevation outside of a trkpt. Help!\n"
      end
      @in_ele = true
    when "time"
      if !@in_trkpt
        puts "Found a time outside of a trkpt. Help!\n"
      end
      @in_time = true
#    else
#      puts "#{name}\n"
    end
  end
  def text(text)
    if @in_time
#      puts "Time: #{text}\n"
      thisTime = parseTime(text)
      @trkpt.time = thisTime
    elsif @in_ele
#      puts "Elevation: #{text}\n"
      @trkpt.ele = text.to_f
    end
  end
  def tag_end(name)
    case name
    when "trkpt"
      @in_trkpt = false
      @current_trkseg << @trkpt
    when "ele"    then @in_ele   = false
    when "time"   then @in_time  = false
    when "trkseg"
      @trksegs << @current_trkseg
    end
  end
end

class Entry
  attr_accessor :lat, :lon, :time, :ele
  def initialize
    @lat  = -180
    @lon  = -200
    @time = Time.at(0)
    @ele  = 0.0
  end
end

gpxlistener = GPXListener.new

meters_per_mile = 1609.344
feet_per_meter = 3.280839895
total_distance = 0

for filename in ARGV
  f = File.open(filename,"r")
  xml = f.read()
  f.close()
  
  gpxlistener.scan(xml)
  
  file_distance = 0
  
  for trkseg in gpxlistener.trksegs
#    puts "trkseg"
    trkseg_distance = 0
    previoustrkpt = trkseg[0]
    maxele  = trkseg[0].ele
    minele  = trkseg[0].ele
    climb   = 0.0
    descend = 0.0
    for trkpt in trkseg[1..-1]
      distance = vincentyInverse([previoustrkpt.lat, previoustrkpt.lon, previoustrkpt.ele], [trkpt.lat, trkpt.lon, trkpt.ele])
      distance = straightLine([previoustrkpt.lat, previoustrkpt.lon], [trkpt.lat, trkpt.lon])
      distance = straightLine([previoustrkpt.lat, previoustrkpt.lon, previoustrkpt.ele], [trkpt.lat, trkpt.lon, trkpt.ele])
      if previoustrkpt.lat == trkpt.lat and previoustrkpt.lon == trkpt.lon and previoustrkpt.ele == previoustrkpt.ele
        next
      end
      
      if trkpt.ele > previoustrkpt.ele
        climb += trkpt.ele - previoustrkpt.ele
      else
        descend += previoustrkpt.ele - trkpt.ele
      end
      
      previoustrkpt = trkpt
#      puts "\ttrkpt: #{trkpt.lat} #{trkpt.lon} #{trkpt.time}"
      trkseg_distance += distance
#      puts "\tdistance: #{distance}"
      if trkpt.ele > maxele
        maxele = trkpt.ele
      end
      if trkpt.ele < minele
        minele = trkpt.ele
      end
    end
    file_distance += trkseg_distance
    puts "Trkseg Distance: #{trkseg_distance/meters_per_mile}mi"
    puts "Minimum Elevation: #{minele*feet_per_meter}ft"
    puts "Maximum Elevation: #{maxele*feet_per_meter}ft"
    puts "Climbed: #{climb*feet_per_meter}ft"
    puts "Descended: #{descend*feet_per_meter}ft"
    puts
  end
  
  puts "File Distance: #{file_distance/meters_per_mile}mi"
  total_distance += file_distance
end
#puts "Total Distance: #{total_distance/meters_per_mile}mi"
