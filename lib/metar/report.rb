# encoding: utf-8

module Metar
  class Report
    ATTRIBUTES = [
      :station_name,
      :station_country,
      :time,
      :wind,
      :visibility,
      :minimum_visibility,
      :present_weather,
      :sky_summary,
      :temperature,
    ]

    attr_reader :parser, :station

    def initialize(parser)
      @parser = parser
      @station = Station.find_by_cccc(@parser.station_code) # TODO: parser should return the station
    end

    def station_name
      @station.name
    end

    def station_country
      @station.country
    end

    def station_code
      @parser.station_code
    end

    def date
      I18n.l(@parser.date)
    end

    def time
      "%u:%02u" % [@parser.time.hour, @parser.time.min]
    end

    def observer
      I18n.t('metar.observer.' + @parser.observer.to_s)
    end

    def wind
      @parser.wind.to_s
    end

    def variable_wind
      @parser.variable_wind.to_s
    end

    def visibility
      @parser.visibility.to_s
    end

    def minimum_visibility
      @parser.minimum_visibility.to_s
    end

    def runway_visible_range
      @parser.runway_visible_range.collect { |rvr| rvr.to_s }.join(', ')
    end

    def present_weather
      @parser.present_weather.join(', ')
    end

    def sky_summary
      return I18n.t('metar.sky_conditions.clear skies') if @parser.sky_conditions.length == 0
      @parser.sky_conditions[-1].to_summary
    end

    def sky_conditions
      @parser.sky_conditions.collect { |sky| sky.to_s }.join(', ')
    end

    def vertical_visibility
      @parser.vertical_visibility.to_s
    end

    def temperature
      @parser.temperature.to_s
    end

    def dew_point
      @parser.dew_point.to_s
    end

    def sea_level_pressure
      @parser.sea_level_pressure.to_s
    end

    def remarks
      @parser.remarks.join(', ')
    end

    def to_s
      attributes.collect do |attribute|
        I18n.t('metar.' + attribute[:attribute].to_s + '.title') + ': ' + attribute[:value]
      end.join("\n") + "\n"
    end

    private

    def attributes
      a = Metar::Report::ATTRIBUTES.map do |key|
        value = self.send(key).to_s
        {:attribute => key, :value => value} if not value.empty?
      end
      a.compact
    end
  end
end
