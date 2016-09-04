require File.join(File.dirname(__FILE__), 'data')

# References:
# WMO = World Meteorological Organization Manual on Codes Volume I.1
#   Section FM 15

module Metar
  class Parser
    def self.for_cccc(cccc)
      raw = Metar::Raw::Noaa.new(cccc)
      new(raw)
    end

    COMPLIANCE = [:strict, :loose]

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

    attr_reader :raw, :metar
    attr_reader :cavok
    attr_reader :wind, :variable_wind, :visibility,
      :minimum_visibility, :runway_visible_range, :present_weather, :sky_conditions,
      :vertical_visibility,
      :recent_weather, :unparsed, :remarks

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

    def observer
      @observer.value
    end

    def temperature
      return nil if @temperature_and_dew_point.nil?
      @temperature_and_dew_point.temperature
    end

    def dew_point
      return nil if @temperature_and_dew_point.nil?
      @temperature_and_dew_point.dew_point
    end

    def sea_level_pressure
      @sea_level_pressure.pressure if @sea_level_pressure
    end

    private

    def analyze
      @chunks = @metar.split(' ')

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

      seek_location
      seek_datetime
      seek_observer
      seek_wind
      seek_variable_wind
      seek_cavok
      if !cavok
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

    def seek_location
      @station_code = Metar::Data::StationCode.parse(@chunks[0])
      if @station_code.nil?
        raise ParseError.new("Expecting location, found '#{ @chunks[0] }' in #{@metar}")
      end
      @chunks.shift
      @station_code
    end

    def seek_datetime
      @time = Metar::Data::Time.parse(
        @chunks[0], year: raw.time.year, month: raw.time.month, strict: strict?
      )
      if !@time
        raise ParseError.new("Expecting datetime, found '#{@chunks[0]}' in #{@metar}")
      end
      @chunks.shift
      @time
    end

    def seek_observer
      @observer = Metar::Data::Observer.parse(@chunks[0])
      @chunks.shift if @observer.raw
      @observer
    end

    def seek_wind
      @wind = Metar::Data::Wind.parse(@chunks[0])
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
        @visibility      = Metar::Data::Visibility.new(
          nil,
          distance: M9t::Distance.kilometers(10), comparator: :more_than
        )
        @present_weather << Metar::Data::WeatherPhenomenon.new(
          nil, phenomenon: "No significant weather"
        )
        @sky_conditions  << SkyCondition.new # = 'clear skies'
        @chunks.shift
        @cavok = true
      else
        @cavok = false
      end
    end

    # 15.10, 15.6.1
    def seek_visibility
      if observer == :auto # WMO 15.4
        if @chunks[0] == '////'
          @chunks.shift # Simply dispose of it
          return
        end
      end

      if @chunks[0] == '1' or @chunks[0] == '2'
        @visibility = Metar::Data::Visibility.parse(@chunks[0] + ' ' + @chunks[1])
        if @visibility
          @chunks.shift
          @chunks.shift
        end
      else
        @visibility = Metar::Data::Visibility.parse(@chunks[0])
        if @visibility
          @chunks.shift
        end
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
      if observer == :auto
        if @chunks[0] == '//' # WMO 15.4
          @present_weather << Metar::Data::WeatherPhenomenon.new(
            nil, phenomenon: "not observed"
          )
          @chunks.shift
          return
        end
      end

      loop do
        wtp = Metar::Data::WeatherPhenomenon.parse(@chunks[0])
        break if wtp.nil?
        @chunks.shift
        @present_weather << wtp
      end
    end

    # Repeatable: 15.9.1.3
    def seek_sky_conditions
      if observer == :auto # WMO 15.4
        if @chunks[0] == '///' or @chunks[0] == '//////'
          @chunks.shift # Simply dispose of it
          return
        end
      end

      loop do
        sky_condition = SkyCondition.parse(@chunks[0])
        break if sky_condition.nil?
        @chunks.shift
        @sky_conditions << sky_condition
      end
    end

    def seek_vertical_visibility
      @vertical_visibility = VerticalVisibility.parse(@chunks[0])
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
        return if @chunks.size == 0
        m = /^RE/.match(@chunks[0])
        break if m.nil?
        recent_weather = Metar::Data::WeatherPhenomenon.parse(m.post_match)
        break if recent_weather.nil?
        @chunks.shift
        @recent_weather << recent_weather
      end
      @recent_weather
    end

    def seek_to_remarks
      if strict?
        if @chunks.size > 0 and @chunks[0] != 'RMK'
          raise ParseError.new("Unparsable text found: '#{@chunks.join(' ')}'")
        end
      else
        while @chunks.size > 0 and @chunks[0] != 'RMK' do
          @unparsed << @chunks.shift
        end
      end
    end

    # WMO: 15.15
    def seek_remarks
      return if @chunks.size == 0
      raise 'seek_remarks called without remark' if @chunks[0] != 'RMK'

      @chunks.shift # Drop 'RMK'
      @remarks = []
      loop do
        break if @chunks.size == 0
        r = Metar::Remark.parse(@chunks[0])
        if r
          if r.is_a?(Array)
            @remarks += r
          else
            @remarks << r
          end
          @chunks.shift
          next
        end
        if @chunks[0] == 'VIS' and @chunks.size >= 3 and @chunks[1] == 'MIN'
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
