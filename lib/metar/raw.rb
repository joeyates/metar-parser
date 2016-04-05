require 'net/ftp'
require 'time'

module Metar

  module Raw

    class Base
      attr_reader :cccc
      attr_reader :metar
      attr_reader :time
      alias :to_s :metar

      def parse
        @cccc = @metar[/\w+/]
      end
    end

    class Data < Base
      def initialize(metar, time = Time.now)
        @metar, @time = metar, time

        parse
      end
    end

    # Collects METAR data from the NOAA site via FTP
    class Noaa < Base
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

        def disconnect
          return if @@connection.nil
          @@connection.close
          @@connection = nil
        end

        def fetch(cccc)
          attempts = 0
          while attempts < 2
            begin
              s = ''
              connection.retrbinary( "RETR #{ cccc }.TXT", 1024 ) do |chunk|
                s << chunk
              end
              return s
            rescue Net::FTPPermError, Net::FTPTempError, EOFError => e
              connect
              attempts += 1
            end
          end
          raise "Net::FTP.retrbinary failed #{attempts} times"
        end

      end

      # Station is a string containing the CCCC code, or
      # an object with a 'cccc' method which returns the code
      def initialize(station)
        @cccc = station.respond_to?(:cccc) ? station.cccc : station
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

      def metar
        fetch
        @metar
      end

      private

      def fetch
        return if @data
        @data = Noaa.fetch(@cccc)
        parse
      end

      def parse
        raw_time, @metar = @data.split("\n")
        @time            = Time.parse(raw_time)
        super
      end

    end

  end

end

