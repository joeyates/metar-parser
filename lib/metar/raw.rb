require 'rubygems' if RUBY_VERSION < '1.9'
require 'net/ftp'

module Metar

  class Raw

    class << self

      @connection = nil

      def cache_connection
        @connection = connection
      end

      def connection
        return @connection if @connection
        connection = Net::FTP.new('tgftp.nws.noaa.gov')
        connection.login
        connection.chdir('data/observations/metar/stations')
        connection
      end

      def fetch(cccc)
        s = ''
        connection.retrbinary("RETR #{ cccc }.TXT", 1024) do |chunk|
          s << chunk
        end
        s
      end

    end

    attr_reader :cccc, :raw, :metar, :time
    alias :to_s :metar

    # Station is a string containing the CCCC code, or
    # an object with a 'cccc' method which returns the code
    def initialize(station)
      @cccc = station.respond_to?(:cccc) ? station.cccc : station
      @raw = Raw.fetch(@cccc)
      time, @metar = @raw.split("\n")
      @time = Time.parse(time)
    end

  end

end
