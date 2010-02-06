require File.dirname(__FILE__) + '/station'

module Metar

  class Report
    # standard can be :international or :united_states
    # observer can be :present, :corrected, :automatic
    attr_reader   :cccc
    attr_accessor :standard, :time, :observer
    attr_accessor :sky, :wind, :visibility, :present_weather
    attr_accessor :temperature, :dew_point, :sea_level_pressure

    def initialize(cccc)
      raise "Station code must not be nil" if cccc.nil?
      @cccc = cccc
    end

    def name
      station.name
    end

    private

    def station
      return @station if @station
      @station = Station.find_by_cccc(@cccc)
    end

  end

end
