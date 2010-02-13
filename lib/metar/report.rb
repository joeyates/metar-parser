require 'rubygems' if RUBY_VERSION < '1.9'
require 'aasm'

module Metar
  STANDARD_WMO       = :wmo
  STANDARD_US        = :us
  OBSERVER_REAL      = :real
  OBSERVER_CORRECTED = :corrected
  OBSERVER_AUTO      = :auto

  class Report
    include AASM

    attr_reader :warnings, :standard, :observer, :location, :datetime, :wind
    
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

    aasm_event :variable_wind do
      transitions :from => :wind,               :to => :variable_wind
    end

    aasm_event :visibility do
      transitions :from => [:wind, :variable_wind],  :to => :visibility
    end

    aasm_event :runway_visible_range do
      transitions :from => [:visibility, :runway_visible_range],         :to => :runway_visible_range
    end

    aasm_event :present_weather do
      transitions :from => [:visibility, :runway_visible_range, :present_weather],
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

    def initialize(raw)
      @metar                = raw.metar.clone
      @chunks               = @metar.split(' ')
      @sky_conditions       = []
      @present_weather      = []
      @remarks              = []
      @runway_visible_range = []
      @warnings             = []
      @observer             = OBSERVER_REAL
    end

    def analyze
      aasm_enter_initial_state
    end

    private

    def set_wmo
      @warnings << "Setting standard to International - already set to United States. Remaining: #{ @chunks.join(' ') }" if @standard == STANDARD_US
      return if @standard == STANDARD_WMO
      @standard = STANDARD_WMO
    end

    def set_us
      @warnings << "Setting standard to United States - already set to International. Remaining: #{ @chunks.join(' ') }" if @standard == STANDARD_WMO
      return if @standard == STANDARD_US
      @standard = STANDARD_US
    end

    def seek_location
      case
      when @chunks[0] =~ /^[A-Z]{4}$/
        @location = @chunks.shift
      when @chunks[0] =~ /^[A-Z]{2}[A-Z0-9]{2}$/
        @warnings << "Illegal CCCC code '#{ @chunks[0] }'"
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
      case
      when @chunks[0] =~ /^\d{5}(G\d{2,3})?(KT)?$/
        @wind = @chunks.shift
      when @chunks[0] =~ /^\d{5}(G\d{2,3})?MPS$/
        @wind = @chunks.shift
      when @chunks[0] =~ /^\d{5}(G\d{2,3})?KMH$/
        @wind = @chunks.shift
      when @chunks[0] =~ /^VRB\d{2}(KT)?$/
        @wind = @chunks.shift
      when @chunks[0] =~ /^VRB\d{2}MPS$/
        @wind = @chunks.shift
      when @chunks[0] =~ /^VRB\d{2}KMH$/
        @wind = @chunks.shift
      else
        error!
        raise "Expecting wind, found '#{ @chunks[0] }'"
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
        @visibility = @chunks.shift # TODO - this sets 3 attributes
        # TODO not used in us
        sky_conditions!
        return
      end

      if @observer == OBSERVER_AUTO # WMO 15.4
        if @chunks[0] == '////'
          @visibility = @chunks.shift # TODO - should be 'not observed'
          visibility!
          return
        end
      end

      case
      when @chunks[0] == '9999'
        @visibility = @chunks.shift
        # Seems to be used in US only
      when (@chunks[0] == '1' and @chunks[1] =~ /^(1\/4|1\/2|3\/4)SM$/)
        @visibility = @chunks.shift + ' ' + @chunks.shift
        set_us
      when (@chunks[0] == '2' and @chunks[1] =~ /^1\/2SM$/)
        @visibility = @chunks.shift + ' ' + @chunks.shift
        set_us
      when @chunks[0] =~ /^\d+KM$/
        @visibility = @chunks.shift
        set_wmo
      when @chunks[0] =~ /^\d+(N|NE|E|SE|S|SW|W|NW)?$/
        @visibility = @chunks.shift
        set_wmo
      when @chunks[0] == 'M1/4SM'
        @visibility = @chunks.shift
        set_us
      when @chunks[0] =~ /^(1\/4|1\/2|3\/4)SM$/
        @visibility = @chunks.shift
        set_us
      # TODO: Other values, which imply manual
      when @chunks[0] =~ /^([1-9]|1[0-5]|[2-9][05])SM$/
        @visibility = @chunks.shift
        set_us
      end
      visibility!
    end

    def collect_runway_visible_range
      case
      when @chunks[0] =~ /^R\d+(R|L|C)?\/(P|M)?\d+(V\d+)?FT$/
        @runway_visible_range << @chunks.shift
        collect_runway_visible_range
      when @chunks[0] =~ /^R\d+\/(P|M)?\d+$/
        # TODO should indicate meters - see end of RVR page
        @runway_visible_range << @chunks.shift
        collect_runway_visible_range
      when @chunks[0] =~ /^R\d+\/\d+(U|D)$/
        # TODO should indicate meters - see end of RVR page
        @runway_visible_range << @chunks.shift
        collect_runway_visible_range
      end
    end

    def seek_runway_visible_range
      collect_runway_visible_range
      runway_visible_range!
    end

    def collect_present_weather
      case
      when @chunks[0] =~ /^(VC|\+|-)?(FZ)?DZ$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(VC|\+|-)?(SH|TS|FZ)?RA$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(VC|\+|-)?(DR|BL|SH|TS)?SN$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(VC|\+|-)?SG$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] == 'IC'
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(VC|\+|-)?(SH|TS)?PL$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(SH|TS)?GR$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(SH|TS)?GS$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] == 'UP'
        @present_weather << @chunks.shift
        collect_present_weather
      # TODO Thunderstorms, Showers, Freezing
      when @chunks[0] =~ /^(-|\+)SHRA$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(-|\+)SHSNRA$/
        @warnings << "Illegal present weather value '#{ @chunks[0] }'"
        @present_weather << @chunks.shift
        collect_present_weather
      # Obscurations
      when @chunks[0] =~ /^(BR|FU|VA|HZ)$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(\+)?(BR|FU|VA|HZ)$/
        @warnings << "Illegal qualifier '#{ $1 }' on '#{ $2 }'"
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(VC|MI|PR|BC|FZ)?FG$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(DR|BL)?(DU|SA)$/
        @present_weather << @chunks.shift
        collect_present_weather
      when @chunks[0] =~ /^(BL)?PY$/
        @present_weather << @chunks.shift
        collect_present_weather
      end
    end

    def seek_present_weather
      if @observer == OBSERVER_AUTO # WMO 15.4
        if @chunks[0] == '//'
          @present_weather << @chunks.shift # TODO - should be 'not observed'
          present_weather!
          return
        end
      end

      collect_present_weather
      present_weather!
    end

    def collect_sky_conditions
      case
      when @chunks[0] == 'CLR'
        @sky_conditions << @chunks.shift
      when @chunks[0] == 'SKC'
        @sky_conditions << @chunks.shift
      when @chunks[0] =~ /^SCT\d+(CB|TCU)?$/
        @sky_conditions << @chunks.shift
        collect_sky_conditions
      when @chunks[0] =~ /^BKN\d+(CB|TCU)?$/
        @sky_conditions << @chunks.shift
        collect_sky_conditions
      when @chunks[0] =~ /^FEW\d+(CB|TCU)?$/
        @sky_conditions << @chunks.shift
        collect_sky_conditions
      when @chunks[0] =~ /^OVC\d+(CB|TCU)?$/
        @sky_conditions << @chunks.shift
        collect_sky_conditions
      when @chunks[0] =~ /^VV(\d{3}|\/\/\/)?$/
        @sky_conditions << @chunks.shift
        collect_sky_conditions
      end
    end

    def seek_sky_conditions
      if @observer == OBSERVER_AUTO # WMO 15.4
        if @chunks[0] == '///' or @chunks[0] == '//////'
          @sky_conditions << @chunks.shift # TODO - should be 'not observed'
          sky_conditions!
          return
        end
      end

      collect_sky_conditions
      sky_conditions!
    end

    def seek_temperature_dew_point
      case
      when @chunks[0] =~ /^M?\d+\/(M?\d+)?$/
        @temperature_dew_point = @chunks.shift
      when @chunks[0] =~ /^(M?\d+)\/(XX)$/
        @warnings << "Illegal dew point value: #{ $2 }"
        @temperature_dew_point = @chunks.shift
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
      @remarks << @chunks.clone
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
