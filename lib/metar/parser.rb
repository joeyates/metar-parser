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
    attr_reader :station_code, :observer, :wind, :variable_wind, :visibility,
      :minimum_visibility, :runway_visible_range, :present_weather, :sky_conditions,
      :vertical_visibility, :temperature, :dew_point, :sea_level_pressure,
      :recent_weather, :unparsed, :remarks

    def initialize(raw)
      @raw   = raw
      @metar = raw.metar.clone
      analyze
    end

    def time
      Time.gm(@raw.time.year, @raw.time.month, @day, @hour, @minute)
    end

    private

    def analyze
      @chunks = @metar.split(' ')

      @station_code         = nil
      @observer             = :real
      @wind                 = nil
      @variable_wind        = nil
      @visibility           = nil
      @minimum_visibility   = nil
      @runway_visible_range = []
      @present_weather      = []
      @sky_conditions       = []
      @vertical_visibility  = nil
      @temperature          = nil
      @dew_point            = nil
      @sea_level_pressure   = nil
      @recent_weather       = []
      @unparsed             = []
      @remarks              = []

      seek_location
      seek_datetime
      seek_cor_auto
      seek_wind
      seek_variable_wind
      cavok = seek_cavok
      if not cavok
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
      if @chunks[0] =~ /^[A-Z][A-Z0-9]{3}$/
        @station_code = @chunks.shift
      else
        raise ParseError.new("Expecting location, found '#{ @chunks[0] }' in #{@metar}")
      end
    end

    def seek_datetime
      found = false
      date_matcher =
        if strict?
          /^(\d{2})(\d{2})(\d{2})Z$/
        else
          /^(\d{1,2})(\d{2})(\d{2})Z$/
        end
      if @chunks[0] =~ date_matcher
        @day, @hour, @minute = $1.to_i, $2.to_i, $3.to_i
        found = true
      else
        if not strict?
          if @chunks[0] =~ /^(\d{1,2})(\d{2})Z$/
            # The day is missing, use today's date
            @day           = Time.now.day
            @hour, @minute = $1.to_i, $2.to_i
            found = true
          end
        end
      end
      if found
        @chunks.shift
      else
        raise ParseError.new("Expecting datetime, found '#{@chunks[0]}' in #{@metar}")
      end
    end

    def seek_cor_auto
      case
      when @chunks[0] == 'AUTO' # WMO 15.4
        @chunks.shift
        @observer = :auto
      when @chunks[0] == 'COR'  # WMO specified code word for correction
        @chunks.shift
        @observer = :corrected
      when @chunks[0] =~ /CC[A-Z]/  # Canadian correction
        # Canada uses CCA for first correction, CCB for second, etc...
        @chunks.shift
        @observer = :corrected
      when @chunks[0] == 'RTD'   #  Delayed observation, no comments on observer
        @chunks.shift
      else
        nil
      end
    end

    def seek_wind
      wind = Wind.parse(@chunks[0])
      if wind
        @chunks.shift
        @wind = wind
      end
    end

    def seek_variable_wind
      variable_wind = VariableWind.parse(@chunks[0])
      if variable_wind
        @chunks.shift
        @variable_wind = variable_wind
      end
    end

    def seek_cavok
      if @chunks[0] == 'CAVOK'
        @chunks.shift
        @visibility      = Visibility.new(M9t::Distance.kilometers(10), nil, :more_than)
        @present_weather << Metar::WeatherPhenomenon.new('No significant weather')
        @sky_conditions  << SkyCondition.new # = 'clear skies'
        return true
      else
        return false
      end
    end

    # 15.10, 15.6.1
    def seek_visibility
      if @observer == :auto # WMO 15.4
        if @chunks[0] == '////'
          @chunks.shift # Simply dispose of it
          return
        end
      end

      if @chunks[0] == '1' or @chunks[0] == '2'
        visibility = Visibility.parse(@chunks[0] + ' ' + @chunks[1])
        if visibility
          @chunks.shift
          @chunks.shift
          @visibility = visibility
        end
      else
        visibility = Visibility.parse(@chunks[0])
        if visibility
          @chunks.shift
          @visibility = visibility
        end
      end
    end

    # Optional after visibility: 15.6.2
    def seek_minimum_visibility
      minimum_visibility = Visibility.parse(@chunks[0])
      if minimum_visibility
        @chunks.shift
        @minimum_visibility = minimum_visibility
      end
    end

    def seek_runway_visible_range
      loop do
        runway_visible_range = RunwayVisibleRange.parse(@chunks[0])
        break if runway_visible_range.nil?
        @chunks.shift
        @runway_visible_range << runway_visible_range
      end
    end

    def seek_present_weather
      if @observer == :auto
        if @chunks[0] == '//' # WMO 15.4
          @chunks.shift # Simply dispose of it
          @present_weather << Metar::WeatherPhenomenon.new('not observed')
          return
        end
      end

      loop do
        wtp = WeatherPhenomenon.parse(@chunks[0])
        break if wtp.nil?
        @chunks.shift
        @present_weather << wtp
      end
    end

    # Repeatable: 15.9.1.3
    def seek_sky_conditions
      if @observer == :auto # WMO 15.4
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
      vertical_visibility = VerticalVisibility.parse(@chunks[0])
      if vertical_visibility
        @chunks.shift
        @vertical_visibility = vertical_visibility
      end
    end

    def seek_temperature_dew_point
      case
      when @chunks[0] =~ /^(M?\d+|XX|\/\/)\/(M?\d+|XX|\/\/)?$/
        @chunks.shift
        @temperature = Metar::Temperature.parse($1)
        @dew_point = Metar::Temperature.parse($2)
      end
    end

    def seek_sea_level_pressure
      sea_level_pressure = Pressure.parse(@chunks[0])
      if sea_level_pressure
        @chunks.shift
        @sea_level_pressure = sea_level_pressure
      end
    end

    def seek_recent_weather
      loop do
        return if @chunks.size == 0
        m = /^RE/.match(@chunks[0])
        break if m.nil?
        recent_weather = Metar::WeatherPhenomenon.parse(m.post_match)
        break if recent_weather.nil?
        @chunks.shift
        @recent_weather << recent_weather
      end
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
      raise 'seek_remarks calls without remark' if @chunks[0] != 'RMK'

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
          r = Metar::VisibilityRemark.parse(@chunks[0])
          @remarks << r
        end
        if @chunks[0] == 'DENSITY' and @chunks.size >= 3 and @chunks[1] == 'ALT'
          @chunks.shift(2)
          r = Metar::DensityAltitude.parse(@chunks[0])
          @remarks << r
        end
        case
        when @chunks[0] =~ /^LTG(|CG|IC|CC|CA)$/
          r = Metar::Lightning.parse_chunks(@chunks)
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
