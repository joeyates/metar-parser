require 'net/ftp'

module Metar

  class Raw

    @@connection = nil

    class << self

      def connection
        return @@connection if @@connection
        connect
        @@connection
      end

      def connect
        @@connection = Net::FTP.new('tgftp.nws.noaa.gov')
        @@connection.login
        @@connection.chdir('data/observations/metar/stations')
        @@connection.passive = true
      end

      def fetch( cccc )
        attempts = 0
        while attempts < 2
          begin
            s = ''
            connection.retrbinary( "RETR #{ cccc }.TXT", 1024 ) do | chunk |
              s << chunk
            end
            return s
          rescue Net::FTPTempError, EOFError => e
            connect
            attempts += 1
          end
        end
        raise "Net::FTP.retrbinary failed #{attempts} times"
      end

    end

    attr_reader :cccc

    # Station is a string containing the CCCC code, or
    # an object with a 'cccc' method which returns the code
    def initialize( station, data = nil )
      @cccc = station.respond_to?(:cccc) ? station.cccc : station
      parse data if data
    end

    def data
      fetch
      @data
    end
    # #raw is deprecated, use #data
    alias :raw :data

    def time
      fetch
      @time
    end

    def raw_time
      fetch
      @raw_time
    end

    def metar
      fetch
      @metar
    end
    alias :to_s :metar

    private

    def fetch
      return if @data
      parse Raw.fetch( @cccc )
    end

    def parse( data )
      @data             = data
      @raw_time, @metar = @data.split( "\n" )
      @time             = Time.parse( @raw_time )
    end

  end

end

