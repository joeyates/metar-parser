# frozen_string_literal: true

require "m9t"

require "metar/data"

# References:
# WMO = World Meteorological Organization Manual on Codes Volume I.1
#   Section FM 15

module Metar
  class Parser
    def self.for_cccc(cccc)
      raw = Metar::Raw::Noaa.new(cccc)
      new(raw)
    end

    COMPLIANCE = %i(strict loose).freeze

    def self.thread_attributes
      Thread.current[:metar_parser] ||= {}
    end

    def self.compliance
      thread_attributes[:compliance] ||= :loose
    end

    def self.compliance=(compliance)
      raise 'Unknown compliance' unless COMPLIANCE.find(compliance)

      thread_attributes[:compliance] = compliance
    end

    attr_reader :raw
    attr_reader :metar
    attr_reader :observer
    attr_reader :wind
    attr_reader :variable_wind
    attr_reader :visibility
    attr_reader :minimum_visibility
    attr_reader :runway_visible_range
    attr_reader :present_weather
    attr_reader :sky_conditions
    attr_reader :vertical_visibility
    attr_reader :temperature_and_dew_point
    attr_reader :sea_level_pressure
    attr_reader :recent_weather
    attr_reader :unparsed
    attr_reader :remarks

    def initialize(raw)
      @raw   = raw
      @metar = raw.metar.clone
      analyze
    end

    def station_code
      @station_code.value
    end

    def time
      @time.value
    end

    def cavok?
      @cavok
    end

    def temperature
      return nil if @temperature_and_dew_point.nil?

      @temperature_and_dew_point.temperature
    end

    def dew_point
      return nil if @temperature_and_dew_point.nil?

      @temperature_and_dew_point.dew_point
    end

    def raw_attributes
      attr = {
        metar: metar,
        datetime: @time.raw,
        station_code: station_code
      }
      %i(
        minimum_visibility
        observer
        sea_level_pressure
        temperature_and_dew_point
        visibility variable_wind vertical_visibility
        wind
      ).each do |key|
        attr = add_raw_if_present(attr, key)
      end
      %i(
        present_weather
        recent_weather remarks runway_visible_range
        sky_conditions
      ).each do |key|
        attr = add_raw_if_not_empty(attr, key)
      end
      attr[:cavok] = "CAVOK" if cavok?
      attr
    end

    private

    def add_raw_if_present(hash, attribute)
      value = send(attribute)
      return hash if value.nil?
      return hash if value.raw.nil?

      hash[attribute] = value.raw
      hash
    end

    def add_raw_if_not_empty(hash, attribute)
      values = send(attribute)
      raws = values.map(&:raw).compact
      return hash if raws.empty?

      hash[attribute] = raws.join(" ")
      hash
    end

    def analyze
      @chunks = @metar.split(' ')
      # Strip final '='
      if !strict?
        @chunks[-1].gsub!(/\s?=$/, '') if !@chunks.empty?
      end

      @station_code         = nil
      @time                 = nil
      @observer             = nil
      @wind                 = nil
      @variable_wind        = nil
      @cavok                = nil
      @visibility           = nil
      @minimum_visibility   = nil
      @runway_visible_range = []
      @present_weather      = []
      @sky_conditions       = []
      @vertical_visibility  = nil
      @temperature_and_dew_point = nil
      @sea_level_pressure   = nil
      @recent_weather       = []
      @unparsed             = []
      @remarks              = []

      seek_station_code
      seek_datetime
      seek_observer
      seek_wind
      seek_variable_wind
      seek_cavok
      if !cavok?
        seek_visibility
        seek_minimum_visibility
        seek_runway_visible_range
        seek_present_weather
        seek_sky_conditions
      end
      seek_vertical_visibility
      seek_temperature_dew_point
      seek_sea_level_pressure
      seek_recent_weather
      seek_to_remarks
      seek_remarks
    end

    def seek_station_code
      @station_code = Metar::Data::StationCode.parse(@chunks[0])
      if @station_code.nil?
        message = "Expecting location, found '#{@chunks[0]}' in #{@metar}"
        raise ParseError, message
      end
      @chunks.shift
      @station_code
    end

    def seek_datetime
      datetime = @chunks.shift
      @time = Metar::Data::Time.parse(
        datetime, year: raw.time.year, month: raw.time.month, strict: strict?
      )

      if !@time
        raise ParseError, "Expecting datetime, found '#{datetime}' in #{@metar}"
      end

      @time
    end

    def seek_observer
      @observer = Metar::Data::Observer.parse(@chunks[0])
      @chunks.shift if @observer.raw
      @observer
    end

    def seek_wind
      @wind = Metar::Data::Wind.parse(@chunks[0], strict: strict?)
      @chunks.shift if @wind
      @wind
    end

    def seek_variable_wind
      @variable_wind = Metar::Data::VariableWind.parse(@chunks[0])
      @chunks.shift if @variable_wind
      @variable_wind
    end

    def seek_cavok
      if @chunks[0] == 'CAVOK'
        @visibility = Metar::Data::Visibility.new(
          nil,
          distance: M9t::Distance.kilometers(10), comparator: :more_than
        )
        @present_weather << Metar::Data::WeatherPhenomenon.new(
          nil, phenomenon: "No significant weather"
        )
        @sky_conditions << Metar::Data::SkyCondition.new(nil) # = 'clear skies'
        @chunks.shift
        @cavok = true
      else
        @cavok = false
      end
    end

    # 15.10, 15.6.1
    def seek_visibility
      if observer.value == :auto # WMO 15.4
        if @chunks[0] == '////'
          @chunks.shift # Simply dispose of it
          return
        end
      end

      if @chunks[0] == '1' || @chunks[0] == '2'
        @visibility = Metar::Data::Visibility.parse(
          @chunks[0] + ' ' + @chunks[1]
        )
        if @visibility
          @chunks.shift
          @chunks.shift
        end
      else
        @visibility = Metar::Data::Visibility.parse(@chunks[0])
        @chunks.shift if @visibility
      end
      @visibility
    end

    # Optional after visibility: 15.6.2
    def seek_minimum_visibility
      @minimum_visibility = Metar::Data::Visibility.parse(@chunks[0])
      @chunks.shift if @minimum_visibility
      @minimum_visibility
    end

    def seek_runway_visible_range
      loop do
        rvr = Metar::Data::RunwayVisibleRange.parse(@chunks[0])
        break if rvr.nil?

        @chunks.shift
        @runway_visible_range << rvr
      end
      @runway_visible_range
    end

    def seek_present_weather
      if observer.value == :auto
        if @chunks[0] == '//' # WMO 15.4
          @present_weather << Metar::Data::WeatherPhenomenon.new(
            nil, phenomenon: "not observed"
          )
          @chunks.shift
          return
        end
      end

      loop do
        break if @chunks.empty?
        break if @chunks[0].start_with?("RE")

        wtp = Metar::Data::WeatherPhenomenon.parse(@chunks[0])
        break if wtp.nil?

        @chunks.shift
        @present_weather << wtp
      end
    end

    # Repeatable: 15.9.1.3
    def seek_sky_conditions
      if observer.value == :auto # WMO 15.4
        if @chunks[0] == '///' || @chunks[0] == '//////'
          @chunks.shift # Simply dispose of it
          return
        end
      end

      loop do
        sky_condition = Metar::Data::SkyCondition.parse(@chunks[0])
        break if sky_condition.nil?

        @chunks.shift
        @sky_conditions << sky_condition
      end
    end

    def seek_vertical_visibility
      @vertical_visibility = Metar::Data::VerticalVisibility.parse(@chunks[0])
      @chunks.shift if vertical_visibility
      @vertical_visibility
    end

    def seek_temperature_dew_point
      @temperature_and_dew_point = Metar::Data::TemperatureAndDewPoint.parse(
        @chunks[0]
      )

      @chunks.shift if @temperature_and_dew_point
      @temperature_and_dew_point
    end

    def seek_sea_level_pressure
      @sea_level_pressure = Metar::Data::Pressure.parse(@chunks[0])
      @chunks.shift if @sea_level_pressure
      @sea_level_pressure
    end

    def seek_recent_weather
      loop do
        return if @chunks.empty?
        break if !@chunks[0].start_with?("RE")

        recent_weather = Metar::Data::WeatherPhenomenon.parse(@chunks[0])
        break if recent_weather.nil?

        @chunks.shift
        @recent_weather << recent_weather
      end
      @recent_weather
    end

    def seek_to_remarks
      if strict?
        if !@chunks.empty? && @chunks[0] != 'RMK'
          raise ParseError, "Unparsable text found: '#{@chunks.join(' ')}'"
        end
      else
        while !@chunks.empty? && @chunks[0] != 'RMK' do
          @unparsed << @chunks.shift
        end
      end
    end

    # WMO: 15.15
    def seek_remarks
      return if @chunks.empty?
      raise 'seek_remarks called without remark' if @chunks[0] != 'RMK'

      @chunks.shift # Drop 'RMK'
      @remarks = []
      loop do
        break if @chunks.empty?

        r = Metar::Data::Remark.parse(@chunks[0])
        if r
          if r.is_a?(Array)
            @remarks += r
          else
            @remarks << r
          end
          @chunks.shift
          next
        end
        if @chunks[0] == 'VIS' && @chunks.size >= 3 && @chunks[1] == 'MIN'
          @chunks.shift(2)
          r = Metar::Data::VisibilityRemark.parse(@chunks[0])
          @remarks << r
        end
        if @chunks[0] == 'DENSITY' && @chunks.size >= 3 && @chunks[1] == 'ALT'
          @chunks.shift(2)
          r = Metar::Data::DensityAltitude.parse(@chunks[0])
          @remarks << r
        end
        case
        when @chunks[0] =~ /^LTG(|CG|IC|CC|CA)$/
          r = Metar::Data::Lightning.parse_chunks(@chunks)
          @remarks << r
        else
          @remarks << @chunks.shift
        end
      end
    end

    def strict?
      self.class.compliance == :strict
    end
  end
end
