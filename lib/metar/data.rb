# encoding: utf-8
require 'i18n'
require 'm9t'

module Metar
  locales_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'locales'))
  I18n.load_path += Dir.glob("#{locales_path}/*.yml")
  I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

  class Distance < M9t::Distance
    attr_accessor :units

    # nil is taken to mean 'data unavailable'
    def initialize(meters = nil)
      @units = :meters
      if meters
        super
      else
        @value = nil
      end
    end

    # Handles nil case differently to M9t::Distance
    def to_s(options = {})
      options = {
        units:       @units,
        precision:   0,
        abbreviated: true,
      }.merge(options)
      return I18n.t('metar.distance.unknown') if @value.nil?
      super(options)
    end
  end

  # Adds a parse method to the M9t base class
  class Speed < M9t::Speed
    METAR_UNITS = {
      ''    => :kilometers_per_hour,
      'KMH' => :kilometers_per_hour,
      'MPS' => :meters_per_second,
      'KT'  => :knots,
    }

    def self.parse(s)
      case
      when s =~ /^(\d+)(|KT|MPS|KMH)$/
        # Call the appropriate factory method for the supplied units
        send(METAR_UNITS[$2], $1.to_i)
      else
        nil
      end
    end
  end

  # Adds a parse method to the M9t base class
  class Temperature < M9t::Temperature
    def self.parse(s)
      if s =~ /^(M?)(\d+)$/
        sign = $1
        value = $2.to_i
        value *= -1 if sign == 'M'
        new(value)
      else
        nil
      end
    end

    def to_s(options = {})
      options = {abbreviated: true, precision: 0}.merge(options)
      super(options)
    end
  end

  class Direction < M9t::Direction
    def initialize(direction)
      direction = M9t::Direction::normalize(direction.to_f)
      super(direction)
    end
  end

  class SkyCondition
    QUANTITY = {'BKN' => 'broken', 'FEW' => 'few', 'OVC' => 'overcast', 'SCT' => 'scattered'}
    CONDITION = {
      'CB'  => 'cumulonimbus',
      'TCU' => 'towering cumulus',
      '///' => nil, # cloud type unknown as observed by automatic system (15.9.1.7)
      ''    => nil,
    }
    CLEAR_SKIES = [
      'NSC', # WMO
      'NCD', # WMO
      'CLR',
      'SKC',
    ]

    def self.parse(sky_condition)
      case
      when CLEAR_SKIES.include?(sky_condition)
        new
      when sky_condition =~ /^(BKN|FEW|OVC|SCT)(\d+|\/{3})(CB|TCU|\/{3}|)?$/
        quantity = QUANTITY[$1]
        height   =
          if $2 == '///'
            nil
          else
            Distance.new($2.to_i * 30.48)
          end
        type = CONDITION[$3]
        new(quantity, height, type)
      when sky_condition =~ /^(CB|TCU)$/
        type = CONDITION[$1]
        new(nil, nil, type)
      else
        nil
      end
    end

    attr_reader :quantity, :height, :type
    def initialize(quantity = nil, height = nil, type = nil)
      @quantity, @height, @type = quantity, height, type
    end

    def to_s
      if @height.nil?
        to_summary
      else
        to_summary + ' ' + I18n.t('metar.altitude.at') + ' ' + height.to_s
      end
    end

    def to_summary
      if @quantity == nil and @height == nil and @type == nil
        I18n.t('metar.sky_conditions.clear skies')
      else
        type = @type ? ' ' + @type : ''
        I18n.t("metar.sky_conditions.#{@quantity}#{type}")
      end
    end
  end

  class VerticalVisibility
    def self.parse(vertical_visibility)
      case
      when vertical_visibility =~ /^VV(\d{3})$/
        Distance.new($1.to_f * 30.48)
      when vertical_visibility == '///'
        Distance.new
      else
        nil
      end
    end
  end

  class Remark
    PRESSURE_CHANGE_CHARACTER = [
      :increasing_then_decreasing, # 0
      :increasing_then_steady,     # 1
      :increasing,                 # 2
      :decreasing_or_steady_then_increasing, # 3
      :steady,                     # 4
      :decreasing_then_increasing, # 5
      :decreasing_then_steady,     # 6
      :decreasing,                 # 7
      :steady_then_decreasing,     # 8
    ]

    INDICATOR_TYPE = {
      'TS'  => :thunderstorm_information,
      'PWI' => :precipitation_identifier,
      'P'   => :precipitation_amount,
    }

    COLOR_CODE = ['RED', 'AMB', 'YLO', 'GRN', 'WHT', 'BLU']

    def self.parse(s)
      case s
      when /^([12])([01])(\d{3})$/
        extreme = {'1' => :maximum, '2' => :minimum}[$1]
        value   = sign($2) * tenths($3)
        TemperatureExtreme.new(extreme, value)
      when /^4([01])(\d{3})([01])(\d{3})$/
        [
          TemperatureExtreme.new(:maximum, sign($1) * tenths($2)),
          TemperatureExtreme.new(:minimum, sign($3) * tenths($4)),
        ]
      when /^5([0-8])(\d{3})$/
        character = PRESSURE_CHANGE_CHARACTER[$1.to_i]
        PressureTendency.new(character, tenths($2))
      when /^6(\d{4})$/
        Precipitation.new(3, Distance.new(inches_to_meters($1))) # actually 3 or 6 depending on reporting time
      when /^7(\d{4})$/
        Precipitation.new(24, Distance.new(inches_to_meters($1)))
      when /^A[0O]([12])$/
        type = [:with_precipitation_discriminator, :without_precipitation_discriminator][$1.to_i - 1]
        AutomatedStationType.new(type)
      when /^P(\d{4})$/
        Precipitation.new(1, Distance.new(inches_to_meters($1)))
      when /^T([01])(\d{3})([01])(\d{3})$/
        temperature = Temperature.new(sign($1) * tenths($2))
        dew_point   = Temperature.new(sign($3) * tenths($4))
        HourlyTemperatureAndDewPoint.new(temperature, dew_point)
      when /^SLP(\d{3})$/
        SeaLevelPressure.new(M9t::Pressure.hectopascals(tenths($1)))
      when /^(#{INDICATOR_TYPE.keys.join('|')})NO$/
        type = INDICATOR_TYPE[$1]
        SensorStatusIndicator.new(:type, :not_available)
      when /^(#{COLOR_CODE.join('|')})$/
        ColorCode.new($1)
      when 'SKC'
        SkyCondition.new
      when '$'
        MaintenanceNeeded.new
      else
        nil
      end
    end

    def self.sign(digit)
      case digit
      when '0'
        1.0
      when '1'
        -1.0
      else
        raise "Unexpected sign: #{digit}"
      end
    end

    def self.tenths(digits)
      digits.to_f / 10.0
    end

    def self.inches_to_meters(digits)
      digits.to_f * 0.000254
    end
  end

  TemperatureExtreme = Struct.new(:extreme, :value)
  PressureTendency = Struct.new(:character, :value)
  Precipitation = Struct.new(:period, :amount)
  AutomatedStationType = Struct.new(:type)
  HourlyTemperatureAndDewPoint = Struct.new(:temperature, :dew_point)
  SeaLevelPressure = Struct.new(:pressure)
  SensorStatusIndicator = Struct.new(:type, :state)
  ColorCode = Struct.new(:code)

  class MaintenanceNeeded; end
end

module Metar::Data
  autoload :Base, "metar/data/base"
  autoload :DensityAltitude, "metar/data/density_altitude"
  autoload :Lightning, "metar/data/lightning"
  autoload :Observer, "metar/data/observer"
  autoload :Pressure, "metar/data/pressure"
  autoload :RunwayVisibleRange, "metar/data/runway_visible_range"
  autoload :StationCode, "metar/data/station_code"
  autoload :TemperatureAndDewPoint, "metar/data/temperature_and_dew_point"
  autoload :Time, "metar/data/time"
  autoload :VariableWind, "metar/data/variable_wind"
  autoload :Visibility, "metar/data/visibility"
  autoload :VisibilityRemark, "metar/data/visibility_remark"
  autoload :WeatherPhenomenon, "metar/data/weather_phenomenon"
  autoload :Wind, "metar/data/wind"
end
