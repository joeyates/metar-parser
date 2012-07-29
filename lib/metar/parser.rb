require 'aasm'
require File.join(File.dirname(__FILE__), 'data')

module Metar

  class Parser
    include AASM

    aasm_initial_state :start

    aasm_state :start,                                       :after_enter => :seek_location
    aasm_state :location,                                    :after_enter => :seek_datetime
    aasm_state :datetime,                                    :after_enter => [:seek_cor_auto, :seek_wind]
    aasm_state :wind,                                        :after_enter => :seek_variable_wind
    aasm_state :variable_wind,                               :after_enter => :seek_visibility
    aasm_state :visibility,                                  :after_enter => :seek_runway_visible_range
    aasm_state :runway_visible_range,                        :after_enter => :seek_present_weather
    aasm_state :present_weather,                             :after_enter => :seek_sky_conditions
    aasm_state :sky_conditions,                              :after_enter => :seek_vertical_visibility
    aasm_state :vertical_visibility,                         :after_enter => :seek_temperature_dew_point
    aasm_state :temperature_dew_point,                       :after_enter => :seek_sea_level_pressure
    aasm_state :sea_level_pressure,                          :after_enter => :seek_remarks
    aasm_state :remarks,                                     :after_enter => :seek_end
    aasm_state :end

    aasm_event :location do
      transitions :from => :start,              :to => :location
    end

    aasm_event :datetime do
      transitions :from => :location,           :to => :datetime
    end

    aasm_event :wind do
      transitions :from => :datetime,           :to => :wind
    end

    aasm_event :cavok do
      transitions :from => :variable_wind,      :to => :sky_conditions
    end

    aasm_event :variable_wind do
      transitions :from => :wind,               :to => :variable_wind
    end

    aasm_event :visibility do
      transitions :from => [:wind, :variable_wind],  :to => :visibility
    end

    aasm_event :runway_visible_range do
      transitions :from => [:visibility],         :to => :runway_visible_range
    end

    aasm_event :present_weather do
      transitions :from => [:runway_visible_range],
                                              :to => :present_weather
    end

    aasm_event :sky_conditions do
      transitions :from => [:present_weather, :visibility, :sky_conditions],
                                                :to => :sky_conditions
    end

    aasm_event :vertical_visibility do
      transitions :from => [:present_weather, :visibility, :sky_conditions],
                                                :to => :vertical_visibility
    end

    aasm_event :temperature_dew_point do
      transitions :from => [:wind, :sky_conditions, :vertical_visibility],   :to => :temperature_dew_point
    end

    aasm_event :sea_level_pressure do
      transitions :from => :temperature_dew_point,   :to => :sea_level_pressure
    end

    aasm_event :remarks do
      transitions :from => [:temperature_dew_point, :sea_level_pressure],
                                                :to => :remarks
    end

    aasm_event :done do
      transitions :from => [:remarks],          :to => :end
    end

    def self.for_cccc(cccc)
      raw = Metar::Raw::Noaa.new(cccc)
      new(raw)
    end

    attr_reader :raw, :metar, :time
    attr_reader :station_code, :observer, :wind, :variable_wind, :visibility, :runway_visible_range,
       :present_weather, :sky_conditions, :vertical_visibility, :temperature, :dew_point, :sea_level_pressure, :remarks

    def initialize(raw)
      @raw   = raw
      @metar = raw.metar.clone
      @time  = raw.time.clone
      analyze
    end

    def date
      Date.new(@time.year, @time.month, @time.day)
    end

    private

    def analyze
      @chunks = @metar.split(' ')

      @station_code         = nil
      @observer             = :real
      @wind                 = nil
      @variable_wind        = nil
      @visibility           = nil
      @runway_visible_range = []
      @present_weather      = []
      @sky_conditions       = []
      @vertical_visibility  = nil
      @temperature          = nil
      @dew_point            = nil
      @sea_level_pressure   = nil
      @remarks              = []

      aasm_enter_initial_state
    end

    def seek_location
      if @chunks[0] =~ /^[A-Z][A-Z0-9]{3}$/
        @station_code = @chunks.shift
      else
        raise ParseError.new("Expecting location, found '#{ @chunks[0] }'")
      end
      location!
    end

    def seek_datetime
      case
      when @chunks[0] =~ /^\d{6}Z$/
        @datetime = @chunks.shift
      else
        raise ParseError.new("Expecting datetime, found '#{ @chunks[0] }'")
      end
      datetime!
    end

    def seek_cor_auto
      case
      when @chunks[0] == 'AUTO' # WMO 15.4
        @chunks.shift
        @observer = :auto
      when @chunks[0] == 'COR'
        @chunks.shift
        @observer = :corrected
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
      wind!
    end

    def seek_variable_wind
      variable_wind = VariableWind.parse(@chunks[0])
      if variable_wind
        @chunks.shift
        @variable_wind = variable_wind
      end
      variable_wind!
    end

    def seek_visibility
      if @chunks[0] == 'CAVOK'
        @chunks.shift
        @visibility = Visibility.new(M9t::Distance.kilometers(10), nil, :more_than)
        @present_weather << Metar::WeatherPhenomenon.new('No significant weather')
        @sky_conditions << SkyCondition.new # = 'clear skies'
        cavok!
        return
      end

      if @observer == :auto # WMO 15.4
        if @chunks[0] == '////'
          @chunks.shift # Simply dispose of it
          visibility!
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
      visibility!
    end

    def collect_runway_visible_range
      runway_visible_range = RunwayVisibleRange.parse(@chunks[0])
      if runway_visible_range
        @chunks.shift
        @runway_visible_range << runway_visible_range
        collect_runway_visible_range
      end
    end

    def seek_runway_visible_range
      collect_runway_visible_range
      runway_visible_range!
    end

    def collect_present_weather
      wtp = WeatherPhenomenon.parse(@chunks[0])
      if wtp
        @chunks.shift
        @present_weather << wtp
        collect_present_weather
      end
    end

    def seek_present_weather
      if @observer == :auto
        if @chunks[0] == '//' # WMO 15.4
          @chunks.shift # Simply dispose of it
          @present_weather << Metar::WeatherPhenomenon.new('not observed')
          present_weather!
          return
        end
      end

      collect_present_weather
      present_weather!
    end

    def collect_sky_conditions
      sky_condition = SkyCondition.parse(@chunks[0])
      if sky_condition
        @chunks.shift
        @sky_conditions << sky_condition
        collect_sky_conditions
      end
    end

    def seek_sky_conditions
      if @observer == :auto # WMO 15.4
        if @chunks[0] == '///' or @chunks[0] == '//////'
          @chunks.shift # Simply dispose of it
          sky_conditions!
          return
        end
      end

      collect_sky_conditions
      sky_conditions!
    end

    def seek_vertical_visibility
      vertical_visibility = VerticalVisibility.parse(@chunks[0])
      if vertical_visibility
        @chunks.shift
        @vertical_visibility = vertical_visibility
      end
      vertical_visibility!
    end

    def seek_temperature_dew_point
      case
      when @chunks[0] =~ /^(M?\d+|XX|\/\/)\/(M?\d+|XX|\/\/)?$/
        @chunks.shift
        @temperature = Metar::Temperature.parse($1)
        @dew_point = Metar::Temperature.parse($2)
      else
        raise ParseError.new("Expecting temperature/dew point, found '#{ @chunks[0] }'")
      end
      temperature_dew_point!
    end

    def seek_sea_level_pressure
      sea_level_pressure = Pressure.parse(@chunks[0])
      if sea_level_pressure
        @chunks.shift
        @sea_level_pressure = sea_level_pressure
      end
      sea_level_pressure!
    end

    def seek_remarks
      if @chunks[0] == 'RMK'
        @chunks.shift
      end
      @remarks += @chunks.clone
      @chunks = []
      remarks!
    end

    def seek_end
      done!
    end

  end

end
