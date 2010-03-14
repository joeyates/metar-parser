# encoding: utf-8
require 'rubygems' if RUBY_VERSION < '1.9'
require 'i18n'
require 'm9t'

module Metar
  locales_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'locales'))
  I18n.load_path += Dir.glob("#{ locales_path }/*.yml")

  class Speed < M9t::Speed

    METAR_UNITS = {
      'KMH' => :kilometers_per_hour,
      'MPS' => :meters_per_second,
      'KT'  => :knots,
    }

    def Speed.parse(s)
      case
      when s =~ /^(\d+)(KT|MPS|KMH)$/
        send(METAR_UNITS[$2], $1.to_i, {:units => METAR_UNITS[$2], :precision => 0})
      when s =~ /^(\d+)$/
        kilometers_per_hour($1.to_i, {:units => :kilometers_per_hour, :precision => 0})
      else
        nil
      end
    end

  end

  class Temperature < M9t::Temperature

    def Temperature.parse(s)
      if s =~ /^(M?)(\d+)$/
        sign = $1
        value = $2.to_i
        value *= -1 if sign == 'M'
        new(value, { :units => :degrees, :precision => 0, :abbreviated => true })
      else
        nil
      end
    end

  end

  class Distance < M9t::Distance

    # Set better defaults for METAR, and handle nil as a special case
    def initialize(meters = nil, options = {})
      if meters
        super(meters, { :units => :kilometers, :precision => 0, :abbreviated => true }.merge(options))
      else
        @value = nil
      end
    end

    def to_s
      return I18n.t('metar.distance.unknown') if @value.nil?
      super
    end

  end

  class Visibility

    def Visibility.parse(s)
      case
      when s == '9999'
        new(Distance.new(10000), nil, :more_than)
      when s =~ /(\d{4})NDV/ # WMO
        new(Distance.new($1.to_f)) # Assuming meters
      when (s =~ /^((1|2)\s|)([13])\/([248])SM$/) # US
        miles = $1.to_f + $3.to_f / $4.to_f
        new(Distance.miles(miles, {:units => :miles}))
      when s =~ /^(\d+)SM$/ # US
        new(Distance.miles($1.to_f, {:units => :miles}))
      when s == 'M1/4SM' # US
        new(Distance.miles(0.25, {:units => :miles}), nil, :less_than)
      when s =~ /^(\d+)KM$/
        new(Distance.kilometers($1))
      when s =~ /^(\d+)$/ # Units?
        new(Distance.kilometers($1))
      when s =~ /^(\d+)(N|NE|E|SE|S|SW|W|NW)$/
        new(Distance.kilometers($1), M9t::Direction.compass($2))
      else
        nil
      end
    end

    attr_reader :distance, :direction, :comparator

    def initialize(distance, direction = nil, comparator = nil)
      @distance, @direction, @comparator = distance, direction, comparator
    end

    def to_s
      case
      when (@direction.nil? and @comparator.nil?)
        @distance.to_s
      when @comparator.nil?
        "%s %s" % [@distance.to_s, @direction.to_s]
      when @direction.nil?
        "%s %s" % [I18n.t('comparison.' + @comparator.to_s), @distance.to_s]
      else
        "%s %s %s" % [I18n.t('comparison.' + @comparator.to_s), @distance.to_s, direction]
      end
    end
  end

  class RunwayVisibleRange

    TENDENCY   = { '' => nil, 'N' => :no_change, 'U' => :improving, 'D' => :worsening }
    COMPARATOR = { '' => nil, 'P' => :more_than, 'M' => :less_than }

    def RunwayVisibleRange.parse(runway_visible_range)
      case
      when runway_visible_range =~ /^R(\d+)\/(P|M|)(\d{4})(N|U|D)?$/
        visibility = Visibility.new(Distance.new($3.to_f), nil, COMPARATOR[$2])
        new($1.to_i, visibility, nil, TENDENCY[$4])
      when runway_visible_range =~ /^R(\d+)\/(\d{4})V(\d{4})(N|U|D)?$/
        maximum = Visibility.new(Distance.new($2.to_f))
        minimum = Visibility.new(Distance.new($3.to_f))
        new($1.to_i, maximum, minimum, TENDENCY[$4])
      end
    end

    attr_reader :number, :visibility1, :visibility2, :tendency
    def initialize(number, visibility1, visibility2, tendency = nil)
      @number, @visibility1, @visibility2, @tendency = number, visibility1, visibility2, tendency
    end

    def to_s
      # TODO: Handle variable visibility
      I18n.t('metar.runway_visible_range.runway') + ' ' + number.to_s + ': ' + visibility1.to_s
    end

  end

  class Wind

    def Wind.parse(s)
      case
      when s =~ /^(\d{3})(\d{2}(KT|MPS|KMH|))$/
        new(M9t::Direction.new($1, { :abbreviated => true }), Speed.parse($2))
      when s =~ /^(\d{3})(\d{2})G(\d{2,3}(KT|MPS|KMH|))$/
        new(M9t::Direction.new($1, { :abbreviated => true }), Speed.parse($2))
      when s =~ /^VRB(\d{2}(KT|MPS|KMH|))$/
        new('variable direction', Speed.parse($1))
      when s =~ /^\/{3}(\d{2}(KT|MPS|KMH|))$/
        new('unknown direction', Speed.parse($1))
      when s =~ /^\/{3}(\/{2}(KT|MPS|KMH|))$/
        new('unknown direction', 'unknown')
      else
        nil
      end
    end

    attr_reader :direction, :speed, :units

    def initialize(direction, speed, units = :kilometers_per_hour)
      @direction, @speed = direction, speed
    end

    def to_s
      "#{ @direction } #{ @speed }"
    end

  end

  class VariableWind
    def VariableWind.parse(variable_wind)
      if variable_wind =~ /^(\d+)V(\d+)$/
        new(M9t::Direction.new($1), M9t::Direction.new($2))
      else
        nil
      end
    end

    attr_reader :direction1, :direction2

    def initialize(direction1, direction2)
      @direction1, @direction2 = direction1, direction2
    end

    def to_s
      "#{ @direction1 } - #{ @direction2 }"
    end

  end

  class WeatherPhenomenon

    Modifiers = {
      '\+' => 'heavy',
      '-'  => 'light',
      'VC' => 'nearby'
    }

    Descriptors = {
      'BC' => 'patches of',
      'BL' => 'blowing',
      'DR' => 'low drifting',
      'FZ' => 'freezing',
      'MI' => 'shallow',
      'PR' => 'partial',
      'SH' => 'shower of',
      'TS' => 'thunderstorm and',
    }

    Phenomena = {
      'BR'   => 'mist',
      'DU'   => 'dust',
      'DZ'   => 'drizzle',
      'FG'   => 'fog',
      'FU'   => 'smoke',
      'GR'   => 'hail',
      'GS'   => 'small hail',
      'HZ'   => 'haze',
      'IC'   => 'ice crystals',
      'PL'   => 'ice pellets',
      'PO'   => 'dust whirls',
      'PY'   => 'spray', # US only
      'RA'   => 'rain',
      'SA'   => 'sand',
      'SH'   => 'shower',
      'SN'   => 'snow',
      'SG'   => 'snow grains',
      'SNRA' => 'snow and rain',
      'SQ'   => 'squall',
      'UP'   => 'unknown phenomenon', # => AUTO
      'VA'   => 'volcanic ash',
      'FC'   => 'funnel cloud',
      'SS'   => 'sand storm',
      'DS'   => 'dust storm',
      'TS'   => 'thunderstorm',
      'TSGR' => 'thunderstorm and hail',
      'TSGS' => 'thunderstorm and small hail',
      'TSRA' => 'thunderstorm and rain',
      'TSRA' => 'thunderstorm and snow',
      'TSRA' => 'thunderstorm and unknown phenomenon', # => AUTO
    }

    def WeatherPhenomenon.parse(s)
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

    attr_reader :phenomenon, :modifier, :descriptor
    def initialize(phenomenon, modifier = nil, descriptor = nil)
      @phenomenon, @modifier, @descriptor = phenomenon, modifier, descriptor
    end

    def to_s
      modifier = @modifier ? @modifier + ' ' : ''
      descriptor = @descriptor ? @descriptor + ' ' : ''
      I18n.t("metar.weather.%s%s%s" % [modifier, descriptor, @phenomenon])
    end

  end

  class SkyCondition

    QUANTITY = {'BKN' => 'broken', 'FEW' => 'few', 'OVC' => 'overcast', 'SCT' => 'scattered'}
    def SkyCondition.parse(sky_condition)
      case
      when (sky_condition == 'NSC' or sky_condition == 'NCD') # WMO
        new
      when sky_condition == 'CLR'
        new
      when sky_condition == 'SKC'
        new
      when sky_condition =~ /^(BKN|FEW|OVC|SCT)(\d+)(CB|TCU|\/{3})?$/
        quantity = QUANTITY[$1]
        height = Distance.new($2.to_i * 30.0, { :units => :meters })
        type = case $3
               when nil
                 nil
               when 'CB'
                 'cumulonimbus'
               when 'TCU'
                 'towering cumulus'
               when '///'
                 ''
               end
        new(quantity, height, type)
      end
    end

    attr_reader :quantity, :height, :type
    def initialize(quantity = nil, height = nil, type = nil)
      @quantity, @height, @type = quantity, height, type
    end

    def to_s
      if @quantity == nil and @height == nil and @type == nil
        'Clear skies'
      else
        type = @type ? ' ' + @type : ''
        I18n.t("metar.sky_conditions.#{ @quantity }#{ type }") + ' ' + I18n.t('metar.altitude.at') + ' ' + height.to_s
      end
    end

  end

  class VerticalVisibility

    def VerticalVisibility.parse(vertical_visibility)
      case
      when vertical_visibility =~ /^VV(\d{3})$/
        Distance.new($1.to_f * 30.0, { :units => :meters })
      when vertical_visibility == '///'
        Distance.new
      end
    end

  end

  class Pressure
    DEFAULT_OPTIONS  = {:units => :bar, :abbreviated => false, :precision => 5}
    KNOWN_UNITS      = [:bar, :pascals, :hectopascals, :kilopascals, :inches_of_mercury]

    # Conversions
    PASCAL          = 0.00001
    HECTOPASCAL     = 100.0 * PASCAL
    KILOPASCAL      = 1000.0 * PASCAL
    INCH_OF_MERCURY = 3386.389 * PASCAL

    include M9t::Base

    def Pressure.hectopascals(hectopascals)
      new(hectopascals * HECTOPASCAL)
    end

    def Pressure.inches_of_mercury(inches_of_mercury)
      new(inches_of_mercury * INCH_OF_MERCURY)
    end

    def Pressure.to_inches_of_mercury(bar)
      bar / INCH_OF_MERCURY
    end

    def Pressure.to_bar(bar)
      bar.to_f
    end

    def Pressure.parse(pressure)
      case
      when pressure =~ /^Q(\d{4})$/
        hectopascals($1.to_f)
      when pressure =~ /^A(\d{4})$/
        inches_of_mercury($1.to_f / 100.0)
      end
    end

    def to_inches_of_mercury
      Pressure.to_inches_of_mercury(@value)
    end

    def to_bar
      Pressure.to_bar(@value)
    end

  end

end
