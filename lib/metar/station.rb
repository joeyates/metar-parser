# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'set'

# A Station can be created without downloading data from the Internet.
# The class downloads and caches the NOAA station list
# when it is first requested.
# As soon of any of the attributes are read, the data is downloaded
# (if necessary), and attributes are set.

module Metar
  class Station
    NOAA_STATION_LIST_URL = 'https://tgftp.nws.noaa.gov/data/nsd_cccc.txt'

    class << self
      @nsd_cccc = nil # Contains the text of the station list

      def countries
        all_structures.reduce(Set.new) { |a, s| a.add(s[:country]) }.to_a.sort
      end

      def all
        all_structures.collect do |h|
          options = h.clone
          cccc    = options.delete(:cccc)
          new(cccc, options)
        end
      end

      def find_by_cccc(cccc)
        all.find { |station| station.cccc == cccc }
      end

      # Does the given CCCC code exist?
      def exist?(cccc)
        !find_data_by_cccc(cccc).nil?
      end

      def find_all_by_country(country)
        all.select { |s| s.country == country }
      end

      def to_longitude(longitude)
        m = longitude.match(/^(\d+)-(\d+)([EW])/)
        return nil if !m

        (m[3] == 'E' ? 1.0 : -1.0) * (m[1].to_f + m[2].to_f / 60.0)
      end

      def to_latitude(latitude)
        m = latitude.match(/^(\d+)-(\d+)([SN])/)
        return nil if !m

        (m[3] == 'E' ? 1.0 : -1.0) * (m[1].to_f + m[2].to_f / 60.0)
      end
    end

    attr_reader :cccc, :name, :state, :country, :longitude, :latitude, :raw
    alias code cccc

    # No check is made on the existence of the station
    def initialize(cccc, noaa_data)
      raise "Station identifier must not be nil"   if cccc.nil?
      raise "Station identifier must not be empty" if cccc.to_s == ''

      @cccc = cccc
      load! noaa_data
    end

    def parser
      raw = Metar::Raw::Noaa.new(@cccc)
      Metar::Parser.new(raw)
    end

    def report
      Metar::Report.new(parser)
    end

    private

    class << self
      @structures = nil

      def download_stations
        uri = URI.parse(NOAA_STATION_LIST_URL)
        response = Net::HTTP.get_response(uri)
        response.body
      end

      def all_structures
        return @structures if @structures

        @nsd_cccc ||= download_stations
        @structures = []

        @nsd_cccc.each_line do |station|
          fields = station.split(';')
          @structures << {
            cccc: fields[0],
            name: fields[3],
            state: fields[4],
            country: fields[5],
            latitude: fields[7],
            longitude: fields[8],
            raw: station.clone
          }
        end

        @structures
      end

      def find_data_by_cccc(cccc)
        all_structures.find { |station| station[:cccc] == cccc }
      end
    end

    def load!(noaa_data)
      @name      = noaa_data[:name]
      @state     = noaa_data[:state]
      @country   = noaa_data[:country]
      @longitude = Station.to_longitude(noaa_data[:longitude])
      @latitude  = Station.to_latitude(noaa_data[:latitude])
      @raw       = noaa_data[:raw]
    end
  end
end
