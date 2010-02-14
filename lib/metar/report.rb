require 'rubygems' if RUBY_VERSION < '1.9'
require 'aasm'
require File.join(File.dirname(__FILE__), 'data')

module Metar
  OBSERVER_REAL      = :real
  OBSERVER_CORRECTED = :corrected
  OBSERVER_AUTO      = :auto

  class Report
    include AASM

    attr_reader :standard, :observer, :location, :datetime, :wind
    
    aasm_initial_state :start

    aasm_state :start,                                       :after_enter => :seek_location
    aasm_state :location,                                    :after_enter => :seek_datetime
    aasm_state :datetime,                                    :after_enter => [:seek_cor_auto, :seek_wind]
    aasm_state :wind,                                        :after_enter => :seek_variable_wind
    aasm_state :variable_wind,                               :after_enter => :seek_visibility
    aasm_state :visibility,                                  :after_enter => :seek_runway_visible_range
    aasm_state :runway_visible_range,                        :after_enter => :seek_present_weather
    aasm_state :present_weather,                             :after_enter => :seek_sky_conditions
    aasm_state :sky_conditions,                              :after_enter => :seek_temperature_dew_point
    aasm_state :temperature_dew_point,                       :after_enter => :seek_sea_level_pressure
    aasm_state :sea_level_pressure,                          :after_enter => :seek_remarks
    aasm_state :remarks,                                     :after_enter => :seek_end
    aasm_state :end
    aasm_state :error

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

    aasm_event :temperature_dew_point do
      transitions :from => [:wind, :sky_conditions],   :to => :temperature_dew_point
    end

    aasm_event :sea_level_pressure do
      transitions :from => :temperature_dew_point,   :to => :sea_level_pressure
    end

    aasm_event :remarks do
      transitions :from => [:temperature_dew_point, :sea_level_pressure],
                                                :to => :remarks
    end

    aasm_event :done do
      transitions :from => [:temperature_dew_point, :sea_level_pressure, :remarks],
                                                :to => :end
    end

    aasm_event :error do
      transitions :from => [:start, :location, :datetime, :wind, :variable_wind, :visibility, :runway_visible_range,
                            :present_weather, :sky_conditions, :temperature_dew_point, :sea_level_pressure, :remarks],
                                                :to => :error
    end

    def Report.for_cccc(cccc)
      station = Metar::Station.new(cccc)
      raw = Metar::Raw.new(station)
      report = Metar::Report.new(raw)
      report.analyze
      report
    end

    def initialize(raw)
      @metar                = raw.metar.clone
      @chunks               = @metar.split(' ')

      @location             = nil
      @time                 = raw.time.clone
      @observer             = OBSERVER_REAL
      @wind                 = nil
      @variable_wind        = nil
      @visibility           = nil
      @runway_visible_range = []
      @present_weather      = []
      @sky_conditions       = []
      @temperature          = nil
      @dew_point            = nil
      @remarks              = []
    end

    def analyze
      aasm_enter_initial_state
    end

    def parts
      a = [
      "Station code: #{ @location }",
      "  Date: #{ @time }",
      "  Observer: #{ @observer }",
      ]
      a << "  Wind: #{ @wind }" if @wind
      a << "  Variable wind: #{ @variable_wind }" if @variable_wind
      a << "  Visibility: #{ @visibility }" if @visibility
      a << "  Runway visible range: #{ @runway_visible_range.join(', ') }" if @runway_visible_range.length > 0
      a << "  Present weather: #{ @present_weather.join(', ') }" if @present_weather.length > 0
      a << "  Sky conditions: #{ @sky_conditions.join(', ') }" if @sky_conditions.length > 0
      a << "  Temperature: #{ @temperature }"
      a << "  Dew point: #{ @dew_point }"
      a << "  Remarks: #{ @remarks.join(', ') }" if @remarks.length > 0
      a
    end

    def to_s
      parts.join("\n")
    end

    private

    def seek_location
      if @chunks[0] =~ /^[A-Z][A-Z0-9]{3}$/
        @location = @chunks.shift
      else
        error!
        raise "Expecting location, found '#{ @chunks[0] }'"
      end
      location!
    end

    def seek_datetime
      case
      when @chunks[0] =~ /^\d{6}Z$/
        @datetime = @chunks.shift
      else
        error!
        raise "Expecting datetime, found '#{ @chunks[0] }'"
      end
      datetime!
    end

    def seek_cor_auto
      case
      when @chunks[0] == 'AUTO' # WMO 15.4
        @chunks.shift
        @observer = OBSERVER_AUTO
      when @chunks[0] == 'COR'
        @chunks.shift
        @observer = OBSERVER_CORRECTED
      end
    end

    def seek_wind
      wind = Wind.recognize(@chunks[0])
      if wind
        @chunks.shift
        @wind = wind
      end
      wind!
    end

    def seek_variable_wind
      if @chunks[0] =~ /^\d+V\d+$/
        @variable_wind = @chunks.shift
      end
      variable_wind!
    end

    def seek_visibility
      if @chunks[0] == 'CAVOK'
        @chunks.shift
        @visibility = Visibility.new('More than 10km')
        @present_weather << Metar::WeatherPhenomenon.new('No significant weather')
        @sky_conditions << 'No significant cloud' # TODO: What does NSC stand for?
        cavok!
        return
      end

      if @observer == OBSERVER_AUTO # WMO 15.4
        if @chunks[0] == '////'
          @chunks.shift
          @visibility = Visibility.new('Not observed')
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
      case
      when @chunks[0] =~ /^R\d+\/(P|M)?\d{4}(N|U)?$/ # U?
        @runway_visible_range << @chunks.shift
        collect_runway_visible_range
      when @chunks[0] =~ /^R\d+\/(P|M)?\d{4}V\d{4}(N)?$/ # U?
        @runway_visible_range << @chunks.shift
        collect_runway_visible_range
      end
    end

    def seek_runway_visible_range
      collect_runway_visible_range
      runway_visible_range!
    end

    def collect_present_weather
      wtp = WeatherPhenomenon.recognize(@chunks[0])
      if wtp
        @chunks.shift
        @present_weather << wtp
        collect_present_weather
      end
    end

    def seek_present_weather
      if @observer == OBSERVER_AUTO
        if @chunks[0] == '//' # WMO 15.4
          @present_weather << Metar::WeatherPhenomenon.new('not observed')
          present_weather!
          return
        end
      end

      collect_present_weather
      present_weather!
    end

    def collect_sky_conditions
      sky_condition = SkyCondition.recognize(@chunks[0])
      if sky_condition
        @chunks.shift
        @sky_conditions << sky_condition
        collect_sky_conditions
      end
    end

    def seek_sky_conditions
      if @observer == OBSERVER_AUTO # WMO 15.4
        if @chunks[0] == '///' or @chunks[0] == '//////'
          @chunks.shift
          @sky_conditions << 'Not observed'
          sky_conditions!
          return
        end
      end

      collect_sky_conditions
      sky_conditions!
    end

    def seek_temperature_dew_point
      case
      when @chunks[0] =~ /^(M?\d+|XX)\/(M?\d+|XX)?$/
        @chunks.shift
        @temperature = Metar::Temperature.new($1)
        @dew_point = Metar::Temperature.new($2)
      else
        error!
        raise "Expecting temperature/dew point, found '#{ @chunks[0] }'"
      end
      temperature_dew_point!
    end

    def seek_sea_level_pressure
      case
      when @chunks[0] =~ /^Q\d+$/
        @sea_level_pressure = @chunks.shift
      when @chunks[0] =~ /^A\d+$/
        @sea_level_pressure = @chunks.shift
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
      if @chunks.length > 0
        error!
        raise "Unexpected tokens found at end of string: found '#{ @chunks.join(' ') }'"
      end
      done!
    end

  end

end
