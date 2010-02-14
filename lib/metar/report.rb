require 'rubygems' if RUBY_VERSION < '1.9'
require 'aasm'

module Metar
  STANDARD_WMO       = :wmo
  STANDARD_US        = :us
  OBSERVER_REAL      = :real
  OBSERVER_CORRECTED = :corrected
  OBSERVER_AUTO      = :auto

  class Temperature
    def initialize(s)
      @unit = :celcius
      if s =~ /^(M?)(\d+)$/
        sign = $1
        value = $2
        if value != 'XX'
          @value = value.to_i
          @value *= -1 if sign == 'M'
        end
      else
        @value = nil
      end
    end

    def to_s
      @value ? "#{ @value } celcius" : 'n.a.'
    end
  end

  class Speed
    UNITS = {
      ''    => :kilometers_per_hour,
      'KMH' => :kilometers_per_hour,
      'KT'  => :knots,
      'MPS' => :meters_per_second      
    }
    def Speed.parse(s)
      if s =~ /^(\d+)(KT|MPS|KMH|)/
        new($1.to_i, UNITS[$2])
      else
      end
    end

    def initialize(value, unit = :kilometers_per_hour)
      @value, @unit = value, unit
    end

    def to_s
      "#{ @value } #{ @unit }"
    end
  end

  class Visibility
    def Visibility.parse(s)
      case
      when s == '9999'
        new('More than 10 km')
      when s =~ /(\d{4})NDV/ # WMO, TODO NDV
        new(Distance.new($1))
      when (s =~ /^((1|2)\s|)([13])\/([24])SM$/) # US
        miles = $1.to_f + $3.to_f / $4.to_f
        new(Distance.new(miles, :miles))
      when s =~ /^(\d+)KM$/
        new(Distance.new($1))
      when s =~ /^(\d+)(N|NE|E|SE|S|SW|W|NW)?$/ # TODO direction
        new(Distance.new($1))
      when s == 'M1/4SM' # US
        new('Less than 1/4 mile')
      when s =~ /^(\d+)SM$/ # US
        new(Distance.new($1, :miles))
      else
        nil
      end
    end

    def initialize(visibility, direction = nil) # visibilty can be String, Distance
      @visibility = visibility
    end

    def to_s
      @visibility.to_s
    end
  end

  class Distance
    def initialize(value, unit = :meters)
      @value, @unit = value, unit
    end

    def to_s
      "#{ @value } #{ @unit }"
    end
  end

  class Wind
    def Wind.recognize(s)
      case
      when s =~ /^(\d{3})(\d{2}(KT|MPS|KMH|))$/
        new($1, Speed.parse($2))
      when s =~ /^(\d{3})(\d{2})G(\d{2,3}(KT|MPS|KMH|))$/
        new($1, Speed.parse($2)) # TODO
      when s =~ /^VRB(\d{2}(KT|MPS|KMH|))$/
        new('variable direction', Speed.parse($2))
      when s =~ /^\/{3}(\d{2}(KT|MPS|KMH|))$/
        new('unknown direction', Speed.parse($2))
      when s =~ /^\/{3}(\/{3}(KT|MPS|KMH|))$/
        new('unknown direction', 'unknown')
      else
        nil
      end
    end

    def initialize(direction, speed)
      @direction, @speed = direction, speed
    end

    def to_s
      "#{ @direction } degrees #{ @speed }"
    end
  end

  class WeatherPhenomenon
    Phenomena = {
      'BR' => 'mist',
      'DU' => 'dust',
      'DZ' => 'drizzle',
      'FG' => 'fog',
      'FU' => 'smoke',
      'GR' => 'hail',
      'GS' => 'small hail',
      'HZ' => 'haze',
      'IC' => 'ice crystals',
      'PL' => 'ice pellets',
      'PO' => 'dust whirls',
      'PY' => '???', # TODO
      'RA' => 'rain',
      'SA' => 'sand',
      'SN' => 'snow',
      'SG' => 'snow grains',
      'SNRA' => 'snow and rain',
      'SQ' => 'squall',
      'UP' => 'unknown phenomenon',
      'VA' => 'volcanic ash',
      'FC' => 'funnel cloud',
      'SS' => 'sand storm',
      'DS' => 'dust strom',
    }

    Descriptors = {
      'BC' => 'patches of ',
      'BL' => 'blowing ',
      'DR' => 'low drifting ',
      'FZ' => 'freezing ',
      'MI' => 'shallow ',
      'PR' => 'partial ',
      'SH' => 'shower of ',
      'TS' => 'thunderstorm and ',
    }

    Modifiers = {
      '\+' => 'heavy ',
      '-' => 'light ',
      'VC' => 'nearby '
    }

    def WeatherPhenomenon.recognize(s)
      codes = Phenomena.keys.join('|')
      descriptors = Descriptors.keys.join('|')
      modifiers = Modifiers.keys.join('|')
      rxp = Regexp.new("^(#{ modifiers })?(#{ descriptors })?(#{ codes })$")
      if rxp.match(s)
        modifier_code = $1
        descriptor_code = $2
        phenomenon_code = $3
        Metar::WeatherPhenomenon.new(Phenomena[phenomenon_code], Modifiers[modifier_code], Descriptors[descriptor_code])
      else
        nil
      end
    end

    def initialize(phenomenon, modifier = nil, descriptor = nil)
      @phenomenon, @modifier, @descriptor = phenomenon, modifier, descriptor
    end

    def to_s
      "#{ @modifier }#{ @descriptor }#{ @phenomenon }"
    end
  end

  class SkyCondition
    def SkyCondition.recognize(s)
      case
      when s == 'NSC' # WMO
        'No significant cloud'
      when s == 'CLR' # TODO - meaning?
        'Clear skies'
      when s == 'SKC' # TODO - meaning?
        'Clear skies'
      when s =~ /^(BKN|FEW|OVC|SCT)(\d+)(CB|TCU|\/{3})?$/
        height = $2.to_i * 30
        type = case $3
               when nil
                 ''
               when 'CB'
                 'cumulonimbus '
               when 'TCU'
                 'towering cumulus '
               when '///'
                 ''
               end
        case $1
        when 'BKN'
          "Broken #{ type }cloud at #{ height }"
        when 'FEW'
          "Few #{ type }clouds at #{ height }"
        when 'OVC'
          "Overcast #{ type }at #{ height }"
        when 'SCT'
          "Scattered #{ type }cloud at #{ height }"
        end
      when s =~ /^VV(\d{3}|\/\/\/)?$/
        height = case $1
                 when '///'
                   'unknown'
                 else
                   $1.to_i
                 end
        "Vertical visibility #{ height }"
      end
    end
  end

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
        @visibility = 'More than 10km'
        @present_weather << Metar::WeatherPhenomenon.new('No significant weather')
        @sky_conditions << 'No significant cloud' # TODO. What does NSC stand for?
        cavok!
        return
      end

      if @observer == OBSERVER_AUTO # WMO 15.4
        if @chunks[0] == '////'
          @visibility = @chunks.shift # TODO - should be 'not observed'
          visibility!
          return
        end
      end

      if @chunks[0] == '1' and @chunks[0] == '2'
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
