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
    aasm_state :datetime,                                    :after_enter => :seek_cor_auto
    aasm_state :wind
    aasm_state :us_wind,              :enter => :set_us
    aasm_state :variable_wind
    aasm_state :visibility
    aasm_state :runway_visible_range
    aasm_state :present_weather
    aasm_state :sky_conditions
    aasm_state :temperature_dew_point
    aasm_state :sea_level_pressure
    aasm_state :remarks
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
      transitions :from => [:sea_level_pressure, :remarks],
                                                :to => :end
    end

    aasm_event :error do
      transitions :from => [:start, :location, :datetime, :wind, :variable_wind, :visibility, :runway_visible_range,
                            :present_weather, :sky_conditions, :temperature_dew_point, :sea_level_pressure, :remarks],
                                                :to => :error
    end

    def initialize(raw)
      @raw                  = raw.clone
      @chunks               = @raw.metar.split(' ')
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
      raise "Can't set standard to International. Remaining: #{ @chunks.join(' ') }" if @standard == STANDARD_US
      return if @standard == STANDARD_WMO
      @standard = STANDARD_WMO
    end

    def set_us
      raise "Can't set standard to United States. Remaining: #{ @chunks.join(' ') }" if @standard == STANDARD_WMO
      return if @standard == STANDARD_US
      @standard = STANDARD_US
      @remarks = []
    end

    def seek_location
      case
      when @chunks[0] =~ /^[A-Z]{4}$/
        @location = @chunks.shift
        location!
      when @chunks[0] =~ /^[A-Z]{2}[A-Z0-9]{2}$/
        @warnings << "Illegal CCCC code '#{ @chunks[0] }'"
        @location = @chunks.shift
        location!
      else
        error!
        raise "Expecting location, found '#{ @chunks[0] }'"
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
      when @chunks[0] =~ /^\d{5}(G\d{2,3})?(KT)?$/
        @wind = @chunks.shift
        wind!
      when @chunks[0] =~ /^\d{5}(G\d{2,3})?MPS$/
        @wind = @chunks.shift
        wind!
      when @chunks[0] =~ /^\d{5}(G\d{2,3})?KMH$/
        @wind = @chunks.shift
        wind!
      when @chunks[0] =~ /^VRB\d{2}(KT)?$/
        @wind = @chunks.shift
        wind!
      when @chunks[0] =~ /^VRB\d{2}MPS$/
        @wind = @chunks.shift
        wind!
      when @chunks[0] =~ /^VRB\d{2}KMH$/
        @wind = @chunks.shift
        wind!
      else
        error!
        raise "Expecting wind, found '#{ @chunks[0] }'"
      end
      seek_variable_wind
    end

    def seek_variable_wind
      if @chunks[0] =~ /^\d+V\d+$/
        @variable_wind = @chunks.shift
        variable_wind!
      end
      seek_visibility
    end

    def seek_visibility
      if @chunks[0] == 'CAVOK'
        @visibility = @chunks.shift # TODO - this sets 3 attributes
        visibility!
        present_weather!
        sky_conditions!
        seek_temperature_dew_point
        # TODO not used in us
        return
      end

      case
      when @chunks[0] == '9999'
        @visibility = @chunks.shift
        visibility!
        # Seems to be used in US only
      when (@chunks[0] == '1' and @chunks[1] =~ /^(1\/4|1\/2|3\/4)SM$/)
        @visibility = @chunks.shift + ' ' + @chunks.shift
        visibility!
        set_us
      when (@chunks[0] == '2' and @chunks[1] =~ /^1\/2SM$/)
        @visibility = @chunks.shift + ' ' + @chunks.shift
        visibility!
        set_us
      when @chunks[0] =~ /^\d+KM$/
        @visibility = @chunks.shift
        visibility!
        set_wmo
      when @chunks[0] =~ /^\d+(N|NE|E|SE|S|SW|W|NW)?$/
        @visibility = @chunks.shift
        visibility!
        set_wmo
      when @chunks[0] == 'M1/4SM'
        @visibility = @chunks.shift
        visibility!
        set_us
      when @chunks[0] =~ /^(1\/4|1\/2|3\/4)SM$/
        @visibility = @chunks.shift
        visibility!
        set_us
      # TODO: Other values, which imply manual
      when @chunks[0] =~ /^([1-9]|1[0-5]|[2-9][05])SM$/
        @visibility = @chunks.shift
        visibility!
        set_us
      end
      seek_runway_visible_range
    end

    def collect_runway_visible_range
      case
      when @chunks[0] =~ /^R\d+(R|L|C)?\/(P|M)?\d+(V\d+)?FT$/
        @runway_visible_range << @chunks.shift
        runway_visible_range!
        collect_runway_visible_range
      when @chunks[0] =~ /^R\d+\/(P|M)?\d+$/
        # TODO should indicate meters - see end of RVR page
        @runway_visible_range << @chunks.shift
        runway_visible_range!
        collect_runway_visible_range
      when @chunks[0] =~ /^R\d+\/\d+(U|D)$/
        # TODO should indicate meters - see end of RVR page
        @runway_visible_range << @chunks.shift
        runway_visible_range!
        collect_runway_visible_range
      end
    end

    def seek_runway_visible_range
      collect_runway_visible_range
      seek_present_weather
    end

    def collect_present_weather
      case
      when @chunks[0] =~ /^(VC|\+|-)?(FZ)?DZ$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(VC|\+|-)?(SH|TS|FZ)?RA$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(VC|\+|-)?(DR|BL|SH|TS)?SN$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(VC|\+|-)?SG$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] == 'IC'
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(VC|\+|-)?(SH|TS)?PL$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(SH|TS)?GR$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(SH|TS)?GS$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] == 'UP'
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      # TODO Thunderstorms, Showers, Freezing
      when @chunks[0] =~ /^(-|\+)SHRA$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(-|\+)SHSNRA$/
        @warnings << "Illegal present weather value '#{ @chunks[0] }'"
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      # Obscurations
      when @chunks[0] =~ /^(BR|FU|VA|HZ)$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(\+)?(BR|FU|VA|HZ)$/
        @warnings << "Illegal qualifier '#{ $1 }' on '#{ $2 }'"
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(VC|MI|PR|BC|FZ)?FG$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(DR|BL)?(DU|SA)$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      when @chunks[0] =~ /^(BL)?PY$/
        @present_weather << @chunks.shift
        present_weather!
        collect_present_weather
      end
    end

    def seek_present_weather
      collect_present_weather
      seek_sky_conditions
    end

    def collect_sky_conditions
      case
      when @chunks[0] == 'CLR'
        @sky_conditions << @chunks.shift
        sky_conditions!
      when @chunks[0] == 'SKC'
        @sky_conditions << @chunks.shift
        sky_conditions!
      when @chunks[0] =~ /^SCT\d+(CB|TCU)?$/
        @sky_conditions << @chunks.shift
        sky_conditions!
        collect_sky_conditions
      when @chunks[0] =~ /^BKN\d+(CB|TCU)?$/
        @sky_conditions << @chunks.shift
        sky_conditions!
        collect_sky_conditions
      when @chunks[0] =~ /^FEW\d+(CB|TCU)?$/
        @sky_conditions << @chunks.shift
        sky_conditions!
        collect_sky_conditions
      when @chunks[0] =~ /^OVC\d+(CB|TCU)?$/
        @sky_conditions << @chunks.shift
        sky_conditions!
        collect_sky_conditions
      when @chunks[0] =~ /^VV(\d{3}|\/\/\/)?$/
        @sky_conditions << @chunks.shift
        sky_conditions!
        collect_sky_conditions
      end
    end

    def seek_sky_conditions
      collect_sky_conditions
      seek_temperature_dew_point
    end

    def seek_temperature_dew_point
      case
      when @chunks[0] =~ /^M?\d+\/(M?\d+)?$/
        @temperature_dew_point = @chunks.shift
        temperature_dew_point!
      when @chunks[0] =~ /^(M?\d+)\/(XX)$/
        @warnings << "Illegal dew point value: #{ $2 }"
        @temperature_dew_point = @chunks.shift
        temperature_dew_point!
      else
        error!
        raise "Expecting temperature/dew point, found '#{ @chunks[0] }'"
      end
      seek_sea_level_pressure
    end

    def seek_sea_level_pressure
      case
      when @chunks[0] =~ /^Q\d+$/
        @sea_level_pressure = @chunks.shift
        sea_level_pressure!
      when @chunks[0] =~ /^A\d+$/
        @sea_level_pressure = @chunks.shift
        sea_level_pressure!
      end
      case
      when @chunks.length == 0
        seek_end
      when @standard == STANDARD_US
        seek_remarks
      when @standard == STANDARD_WMO
        seek_wmo_remarks
      else
        raise "Got to SLP without deciding standard. Remaining: #{ @chunks.join(' ') }"
      end
    end

    def seek_remarks
      case
      when @chunks[0] == 'RMK'
        remarks!
        @chunks.shift
        @remarks << @chunks.clone
        @chunks = []
        set_us
      end
      seek_end
    end

    def collect_wmo_remarks
      case
      when @chunks[0] == 'RMK'
        @chunks.shift
        remarks!
      when @chunks[0] == 'NOSIG'
        @remarks << 'NOSIG'
        remarks!
      when @chunks[0] =~ /RE(DZ|RA|SN|SG|IC|GR|GS|UP)/ # UP possible?
        @remarks << @chunks.shift
        remarks!
      when @chunks[0] == 'TEMPO'
        @remarks << @chunks.clone
        @chunks = []
        remarks!
      when @chunks[0] == 'BECMG'
        @remarks << @chunks.clone
        @chunks = []
        remarks!
      when (@chunks[0] == 'WS' and @chunks[1] =~ /(TKOF|LDG)/ and @chunks[2] =~ /RWY\d+/)
        @remarks << (@chunks.shift + ' ' + @chunks.shift + ' ' + @chunks.shift)
        remarks!
      end
    end

    def seek_wmo_remarks
      collect_wmo_remarks
      seek_end
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
