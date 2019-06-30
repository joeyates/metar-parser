# frozen_string_literal: true

require 'date'
require 'net/ftp'
require 'time'

module Metar
  module Raw
    class Base
      attr_reader :metar
      attr_reader :time
      alias to_s metar
    end

    ##
    # Use this class when you have a METAR string and the date of reading
    class Data < Base
      def initialize(metar, time = nil)
        if time.nil?
          warn <<-WARNING
          Using Metar::Raw::Data without a time parameter is deprecated.
          Please supply the reading time as the second parameter.
          WARNING
          time = Time.now
        end

        @metar = metar
        @time = time
      end
    end

    ##
    # Use this class when you only have a METAR string.
    # The date of the reading is decided as follows:
    # * the day of the month is extracted from the METAR,
    # * the most recent day with that day of the month is taken as the
    #   date of the reading.
    class Metar < Base
      def initialize(metar)
        @metar = metar
        @time = nil
      end

      def time
        return @time if @time

        dom = day_of_month
        date = Date.today
        loop do
          if date.day >= dom
            @time = Date.new(date.year, date.month, dom)
            break
          end
          # skip to the last day of the previous month
          date = Date.new(date.year, date.month, 1).prev_day
        end
        @time
      end

      private

      def datetime
        datetime = metar[/^\w{4} (\d{6})Z/, 1]
        raise "The METAR string must have a 6 digit datetime" if datetime.nil?

        datetime
      end

      def day_of_month
        dom = datetime[0..1].to_i
        raise "Day of month must be at most 31" if dom > 31
        raise "Day of month must be greater than 0" if dom.zero?

        dom
      end
    end

    # Collects METAR data from the NOAA site via FTP
    class Noaa < Base
      def self.fetch(cccc)
        connection = Net::FTP.new('tgftp.nws.noaa.gov')
        connection.login
        connection.chdir('data/observations/metar/stations')
        connection.passive = true

        attempts = 0
        while attempts < 2
          begin
            s = ''
            connection.retrbinary("RETR #{cccc}.TXT", 1024) do |chunk|
              s += chunk
            end
            connection.close
            return s
          rescue Net::FTPPermError, Net::FTPTempError, EOFError
            attempts += 1
          end
        end

        raise "Net::FTP.retrbinary failed #{attempts} times"
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
      alias raw data

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
        @time            = Time.parse(raw_time + " UTC")
      end
    end
  end
end
