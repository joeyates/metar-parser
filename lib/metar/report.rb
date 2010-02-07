require 'rubygems' if RUBY_VERSION < '1.9'
require 'aasm'

module Metar
  STANDARD_INT       = :int
  STANDARD_US        = :us
  OBSERVER_REAL      = :real
  OBSERVER_CORRECTED = :corrected
  OBSERVER_AUTO      = :auto

  class Report
    include AASM

    attr_reader :standard, :observer, :location, :datetime, :wind
    
    aasm_initial_state :start

    aasm_state :start,                                       :after_enter => :seek_location
    aasm_state :location,                                    :after_enter => :seek_datetime
    aasm_state :datetime,                                    :after_enter => :seek_cor_auto
    aasm_state :wind,                                        :after_enter => :seek_variable_wind
    aasm_state :us_wind,              :enter => :set_us,     :after_enter => :seek_variable_wind
    aasm_state :variable_wind
    aasm_state :visibility,           :enter => :set_int
    aasm_state :us_visibility,        :enter => :set_us
    aasm_state :runway_visible_range,                        :after_enter => :seek_present_weather
    aasm_state :present_weather
    aasm_state :sky_conditions
    aasm_state :temperature_dew_point
    aasm_state :sea_level_pressure,    :enter => :set_int
    aasm_state :us_sea_level_pressure, :enter => :set_us

=begin

    aasm_state :recent_weather,                 :enter => :set_int
    aasm_state :us_remarks,                     :enter => :set_us
    aasm_state :takeoff_and_landing_conditions, :enter => :set_int

=end

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

    aasm_event :variable_wind do
      transitions :from => :wind,               :to => :variable_wind
    end

    aasm_event :visibility do
      transitions :from => [:wind, :variable_wind],  :to => :visibility
    end

    aasm_event :us_visibility do
      transitions :from => [:wind, :variable_wind],  :to => :us_visibility
    end

    aasm_event :runway_visible_range do
      transitions :from => :visibility,         :to => :runway_visible_range
    end

    aasm_event :present_weather do
      transitions :from => :runway_visible_range,   :to => :present_weather
    end

    aasm_event :sky_conditions do
      transitions :from => [:present_weather, :visibility, :us_visibility, :sky_conditions],
                                                :to => :sky_conditions
    end

    aasm_event :temperature_dew_point do
      transitions :from => :sky_conditions,   :to => :temperature_dew_point
    end

    aasm_event :sea_level_pressure do
      transitions :from => :temperature_dew_point,   :to => :sea_level_pressure
    end

    aasm_event :us_sea_level_pressure do
      transitions :from => :temperature_dew_point,   :to => :us_sea_level_pressure
    end

    aasm_event :error do
      transitions :from => [:start, :location, :datetime, :wind, :variable_wind, :visibility, :us_visibility],
                                                :to => :error
    end

    def initialize(raw)
      @raw            = raw.clone
      @chunks         = @raw.metar.split(' ')
      @sky_conditions = []
      @observer       = OBSERVER_REAL
    end

    def analyze
      aasm_enter_initial_state
    end

    private

    def set_int
      raise "Can't set standard to International" if @standard == STANDARD_US
      @standard = STANDARD_INT
    end

    def set_us
      raise "Can't set standard to United States" if @standard == STANDARD_INT
      @standard = STANDARD_US
    end

    def seek_location
      case
      when @chunks[0] =~ /^[A-Z]{4}$/
        @location = @chunks.shift
        location!
      else
        error!
        raise "Expecting datetime, found '#{ @chunks[0] }'"
      end
    end

    def seek_datetime
      case
      when @chunks[0] =~ /^\d{6}Z$/
        @datetime = @chunks.shift
        datetime!
      else
        error!
        raise "Expecting datetime, found '#{ @chunks[0] }'"
      end
    end

    def seek_cor_auto
      case
      when @chunks[0] == 'AUTO'
        @chunks.shift
        @observer = OBSERVER_AUTO
        set_us
      when @chunks[0] == 'COR'
        @chunks.shift
        @observer = OBSERVER_CORRECTED
        set_us
      end
      seek_wind
    end

    def seek_wind
      case
      when @chunks[0] =~ /^\d{5}KT$/
        @wind = @chunks.shift
        wind!
      else
        error!
        raise "Expecting wind, found '#{ @chunks[0] }'"
      end
    end

    def seek_variable_wind
      if @chunks[0] =~ /^\d+V\d+$/
        @variable_wind = @chunks.shift
        variable_wind!
      end
      seek_visibility
    end

    def seek_visibility
      case
      when @chunks[0] == '9999'
        @visibility = @chunks.shift
        visibility!
      when @chunks[0] =~ /^\d{1,4}$/
        @chunks.shift
        visibility!
      when @chunks[0] =~ /^\d{1,4}SM$/
        @chunks.shift
        us_visibility!
      else
        error!
        raise "Expecting visibility, found '#{ @chunks[0] }'"
      end
      seek_runway_visible_range
    end

    def seek_runway_visible_range
      if @chunks[0] =~ /^\d+V\d+$/
        @runway_visible_range = @chunks.shift
        runway_visible_range!
      else
        seek_present_weather
      end
    end

    def seek_present_weather
      if @chunks[0] =~ /^\d+V\d+$/
        @present_weather = @chunks.shift
        present_weather!
      else
        seek_sky_conditions
      end
    end

    def seek_sky_conditions
      case
      when @chunks[0] == 'CLR'
        @sky_conditions << @chunks.shift
        sky_conditions!
      when @chunks[0] =~ /^SCT\d+$/
        @sky_conditions << @chunks.shift
        sky_conditions!
        seek_sky_conditions
      when @chunks[0] =~ /^BKN\d+$/
        @sky_conditions << @chunks.shift
        sky_conditions!
        seek_sky_conditions
      end
      seek_temperature_dew_point
    end

    def seek_temperature_dew_point
      case
      when @chunks[0] =~ /^M?\d+\/(M?\d+)?$/
        @temperature_dew_point = @chunks.shift
        temperature_dew_point!
      else
        error!
        raise "Expecting temperature/dew point, found '#{ @chunks[0] }'"
      end
      case @standard
      when STANDARD_US
        seek_us_sea_level_pressure
      when STANDARD_INT
        seek_sea_level_pressure
      end
    end

    def seek_sea_level_pressure
      case
      when @chunks[0] =~ /^Q\d+$/
        @sea_level_pressure = @chunks.shift
        sea_level_pressure!
      else
        error!
        raise "Expecting sea level pressure, found '#{ @chunks[0] }'"
      end
    end

    def seek_us_sea_level_pressure
      case
      when @chunks[0] =~ /^A\d+$/
        @sea_level_pressure = @chunks.shift
        us_sea_level_pressure!
      else
        error!
        raise "Expecting sea level pressure, found '#{ @chunks[0] }'"
      end
    end

  end

end
