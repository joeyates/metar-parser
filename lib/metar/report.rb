# encoding: utf-8

module Metar

  class Report

    KNOWN_ATTRIBUTES =
      [
       :station_code, :station_name, :station_country,
       :date, :time, :observer,
       :wind, :variable_wind,
       :visibility, :runway_visible_range,
       :present_weather,
       :sky_summary, :sky_conditions,
       :temperature, :dew_point, :remarks
      ]

    DEFAULT_ATTRIBUTES =
      [
       :station_name, :station_country,
       :time,
       :wind,
       :visibility,
       :present_weather,
       :sky_summary,
       :temperature
      ]

    instance_eval do

      def reset_options!
        @attributes = DEFAULT_ATTRIBUTES.clone
      end

      def attributes
        @attributes
      end

      def attributes=(attributes)
        @attributes = attributes.clone
      end

      reset_options!
    end

    attr_reader :parser, :station

    def initialize(parser)
      @parser = parser
      @station = Station.find_by_cccc(@parser.station_code)
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
      "%u:%u" % [@parser.time.hour, @parser.time.min]
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

    def runway_visible_range
      @parser.runway_visible_range.collect { |rvr| rvr.to_s }.join(', ')
    end

    def present_weather
      @parser.present_weather.join( ', ' )
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
    
    def attributes
      Metar::Report.attributes.reduce([]) do |memo, key|
        value = self.send(key).to_s
        memo << {:attribute => key, :value => value} if not value.empty?
        memo
      end
    end

    def to_s
      attributes.collect do |attribute|
        I18n.t('metar.' + attribute[:attribute].to_s + '.title') + ': ' + attribute[:value]
      end.join("\n")
    end

  end

end
