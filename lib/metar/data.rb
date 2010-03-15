# encoding: utf-8
require 'rubygems' if RUBY_VERSION < '1.9'
require 'i18n'
require 'm9t'

module Metar
  locales_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'locales'))
  I18n.load_path += Dir.glob("#{ locales_path }/*.yml")

  # Subclasses M9t::Distance
  # Uses kilometers as desired default output unit
  class Distance < M9t::Distance

    # nil is taken to mean 'data unavailable'
    def initialize(meters = nil, options = {})
      if meters
        super(meters, { :units => :kilometers, :precision => 0, :abbreviated => true }.merge(options))
      else
        @value = nil
      end
    end

    # Handles nil case differently to M9t::Distance
    def to_s
      return I18n.t('metar.distance.unknown') if @value.nil?
      super
    end

  end

  # Adds a parse method to the M9t base class
  class Speed < M9t::Speed

    METAR_UNITS = {
      'KMH' => :kilometers_per_hour,
      'MPS' => :meters_per_second,
      'KT'  => :knots,
    }

    def Speed.parse(s)
      case
      when s =~ /^(\d+)(KT|MPS|KMH)$/
        # Call the appropriate factory method for the supplied units
        send(METAR_UNITS[$2], $1.to_i, { :units => :kilometers_per_hour, :precision => 0, :abbreviated => true })
      when s =~ /^(\d+)$/
        kilometers_per_hour($1.to_i, { :units => :kilometers_per_hour, :precision => 0, :abbreviated => true })
      else
        nil
      end
    end

  end

  # Adds a parse method to the M9t base class
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

  # Adds a parse method to the M9t base class
  class Pressure < M9t::Pressure

    def Pressure.parse(pressure)
      case
      when pressure =~ /^Q(\d{4})$/
        hectopascals($1.to_f)
      when pressure =~ /^A(\d{4})$/
        inches_of_mercury($1.to_f / 100.0)
      else
        nil
      end
    end

  end

  class Wind
    
    def Wind.parse(s)
      case
      when s =~ /^(\d{3})(\d{2}(|MPS|KMH|KT))$/
        new(M9t::Direction.new($1, { :units => :compass, :abbreviated => true }), Speed.parse($2))
      when s =~ /^(\d{3})(\d{2})G(\d{2,3}(|MPS|KMH|KT))$/
        new(M9t::Direction.new($1, { :units => :compass, :abbreviated => true }), Speed.parse($2))
      when s =~ /^VRB(\d{2}(|MPS|KMH|KT))$/
        new(:variable_direction, Speed.parse($1))
      when s =~ /^\/{3}(\d{2}(|MPS|KMH|KT))$/
        new(:unknown_direction, Speed.parse($1))
      when s =~ /^\/{3}(\/{2}(|MPS|KMH|KT))$/
        new(:unknown_direction, :unknown)
      else
        nil
      end
    end

    attr_reader :direction, :speed, :units

    def initialize(direction, speed, units = :kilometers_per_hour)
      @direction, @speed = direction, speed
    end

    def to_s
      direction =
        case @direction
        when :variable_direction
          I18n.t('metar.wind.variable_direction')
        when :unknown_direction
          I18n.t('metar.wind.unknown_direction')
        else
          @direction.to_s
        end
      speed =
        case @speed
        when :unknown
          I18n.t('metar.wind.unknown_speed')
        else
          @speed.to_s
        end  
      "#{ speed } #{ direction }"
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
    UNITS      = { '' => :meters, 'FT' => :feet }

    def RunwayVisibleRange.parse(runway_visible_range)
      case
      when runway_visible_range =~ /^R(\d+[RLC]?)\/(P|M|)(\d{4})(N|U|D|)(FT|)$/
        designator = $1
        comparator = COMPARATOR[$2]
        count      = $3.to_f
        tendency   = TENDENCY[$4]
        units      = UNITS[$5]
        distance   = Distance.send(units, count, { :units => units })
        visibility = Visibility.new(distance, nil, comparator)
        new(designator, visibility, nil, tendency)
      when runway_visible_range =~ /^R(\d+[RLC]?)\/(P|M|)(\d{4})V(P|M|)(\d{4})(N|U|D)?(FT)?$/
        designator  = $1
        comparator1 = COMPARATOR[$2]
        count1      = $3.to_f
        comparator2 = COMPARATOR[$4]
        count2      = $5.to_f
        tendency    = TENDENCY[$6]
        units       = UNITS[$7]
        distance1   = Distance.send(units, count1, { :units => units })
        distance2   = Distance.send(units, count2, { :units => units })
        visibility1 = Visibility.new(distance1, nil, comparator1)
        visibility2 = Visibility.new(distance2, nil, comparator2)
        new(designator, visibility1, visibility2, tendency)
      else
        nil
      end
    end

    attr_reader :designator, :visibility1, :visibility2, :tendency
    def initialize(designator, visibility1, visibility2 = nil, tendency = nil)
      @designator, @visibility1, @visibility2, @tendency = designator, visibility1, visibility2, tendency
    end

    def to_s
      if @visibility2.nil?
        I18n.t('metar.runway_visible_range.runway') + ' ' + @designator + ': ' + @visibility1.to_s
      else
        I18n.t('metar.runway_visible_range.runway') + ' ' + @designator + ': ' + I18n.t('metar.runway_visible_range.from') + ' ' + @visibility1.to_s + ' ' + I18n.t('metar.runway_visible_range.to') + ' ' + @visibility2.to_s
      end
    end

  end

  class WeatherPhenomenon

    Modifiers = {
      '+' => 'heavy',
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

    # Accepts all standard (and some non-standard) present weather codes
    def WeatherPhenomenon.parse(s)
      codes = Phenomena.keys.join('|')
      descriptors = Descriptors.keys.join('|')
      modifiers = Modifiers.keys.join('|')
      modifiers.gsub!(/([\+\-])/) { "\\#$1" }
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
      I18n.t("metar.present_weather.%s%s%s" % [modifier, descriptor, @phenomenon])
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
        type =
          case $3
          when 'CB'
            'cumulonimbus'
          when 'TCU'
            'towering cumulus'
          when nil
            nil
          when '///'
            nil
          else
            raise ParseError.new("Unexpected sky condition type: #$3")
          end
        new(quantity, height, type)
      else
        nil
      end
    end

    attr_reader :quantity, :height, :type
    def initialize(quantity = nil, height = nil, type = nil)
      @quantity, @height, @type = quantity, height, type
    end

    def to_s
      conditions = to_summary
      conditions += ' ' + I18n.t('metar.altitude.at') + ' ' + height.to_s if not @height.nil?
      conditions
    end

    def to_summary
      if @quantity == nil and @height == nil and @type == nil
        I18n.t('metar.sky_conditions.clear skies')
      else
        type = @type ? ' ' + @type : ''
        I18n.t("metar.sky_conditions.#{ @quantity }#{ type }")
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
      else
        nil
      end
    end

  end

end
