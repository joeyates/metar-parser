#!/usr/bin/env ruby

=begin

This script downloads the current weather report for each station.

=end

require 'rubygems' if RUBY_VERSION < '1.9'
require 'yaml'
require File.join(File.expand_path(File.dirname(__FILE__) + '/../lib'), 'metar')

Metar::Station.load_local

('A'..'Z').each do |initial|

  stations = {}

  Metar::Station.all.each do |station|

    next if station.cccc[0, 1] < initial
    break if station.cccc[0, 1] > initial

    print station.cccc
    raw = nil
    begin
      raw = Metar::Raw.new(station.cccc)
    rescue Net::FTPPermError => e
      puts ": Not available - #{ e }"
      next
    rescue
      puts ": Other error - #{ e }"
      next
    end

    stations[station.cccc] = raw.raw.clone
    puts ': OK'
  end

  filename = File.join(File.expand_path(File.dirname(__FILE__) + '/../data'), "stations.#{ initial }.yml")
  File.open(filename, 'w') { |fil| fil.write stations.to_yaml }

end

# Merge into one file
stations = {}
('A'..'Z').each do |initial|
  filename = File.join(File.expand_path(File.dirname(__FILE__) + '/../data'), "stations.#{ initial }.yml")
  next if not File.exist?(filename)
  h = YAML.load_file(filename)
  stations.merge!(h)
end

filename = File.join(File.expand_path(File.dirname(__FILE__) + '/../data'), "stations.yml")
File.open(filename, 'w') { |fil| fil.write stations.to_yaml }
