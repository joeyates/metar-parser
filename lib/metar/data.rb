# encoding: utf-8
require 'i18n'
require 'm9t'

module Metar
  locales_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'locales'))
  I18n.load_path += Dir.glob("#{ locales_path }/*.yml")

  class Distance < M9t::Distance

    attr_accessor :units

    # nil is taken to mean 'data unavailable'
    def initialize( meters = nil )
      @units = :meters
      if meters
        super
      else
        @value = nil
      end
    end

    # Handles nil case differently to M9t::Distance
    def to_s( options = {} )
      options = { :units       => @units,
                  :precision   => 0,
                  :abbreviated => true }.merge( options )
      return I18n.t('metar.distance.unknown') if @value.nil?
      super( options )
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

    def Speed.parse(s)
      case
      when s =~ /^(\d+)(|KT|MPS|KMH)$/
        # Call the appropriate factory method for the supplied units
        send( METAR_UNITS[$2], $1.to_i )
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
        new( value )
      else
        nil
      end
    end

    def to_s( options = {} )
      options = { :abbreviated => true, :precision => 0 }.merge( options )
      super( options )
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

  class Direction < M9t::Direction
    def initialize( direction )
      direction = M9t::Direction::normalize( direction.to_f )
      super( direction )
    end
  end

  class Wind
    
    def Wind.parse(s)
      case
      when s =~ /^(\d{3})(\d{2}(|MPS|KMH|KT))$/
        return nil if $1.to_i > 360
        new( Direction.new( $1 ),
             Speed.parse( $2 ) )
      when s =~ /^(\d{3})(\d{2})G(\d{2,3}(|MPS|KMH|KT))$/
        return nil if $1.to_i > 360
        new( Direction.new( $1 ),
             Speed.parse( $2 + $4 ),
             Speed.parse( $3 ) )
      when s =~ /^VRB(\d{2}(|MPS|KMH|KT))$/
        new( :variable_direction,
             Speed.parse($1))
      when s =~ /^\/{3}(\d{2}(|MPS|KMH|KT))$/
        new( :unknown_direction,
             Speed.parse($1))
      when s =~ %r(^/////(|MPS|KMH|KT)$)
        new( :unknown_direction,
             :unknown_speed)
      else
        nil
      end
    end

    attr_reader :direction, :speed, :gusts

    def initialize( direction, speed, gusts = nil )
      @direction, @speed, @gusts = direction, speed, gusts
    end

    def to_s( options = {} )
      options = { :direction_units => :compass,
                  :speed_units     => :kilometers_per_hour }.merge( options )
      speed =
        case @speed
        when :unknown_speed
          I18n.t('metar.wind.unknown_speed')
        else
          @speed.to_s( :abbreviated => true,
                       :precision   => 0,
                       :units       => options[ :speed_units ] )
        end
      direction =
        case @direction
        when :variable_direction
          I18n.t('metar.wind.variable_direction')
        when :unknown_direction
          I18n.t('metar.wind.unknown_direction')
        else
          @direction.to_s( :units => options[ :direction_units ] )
        end
      s = "#{ speed } #{ direction }"
      if ! @gusts.nil?
        g =  @gusts.to_s( :abbreviated => true,
                          :precision   => 0,
                          :units       => options[ :speed_units ] )
        s += " #{ I18n.t('metar.wind.gusts') } #{ g }"
      end
      s
    end

  end

  class VariableWind

    def VariableWind.parse(variable_wind)
      if variable_wind =~ /^(\d+)V(\d+)$/
        new(Direction.new($1), Direction.new($2))
      else
        nil
      end
    end

    attr_reader :direction1, :direction2

    def initialize(direction1, direction2)
      @direction1, @direction2 = direction1, direction2
    end

    def to_s
      "#{ @direction1.to_s( :units => :compass ) } - #{ @direction2.to_s( :units => :compass ) }"
    end

  end

  class Visibility

    def Visibility.parse(s)
      case
      when s == '9999'
        new( Distance.new( 10000 ), nil, :more_than )
      when s =~ /(\d{4})NDV/ # WMO
        new( Distance.new( $1.to_f ) ) # Assuming meters
      when (s =~ /^((1|2)\s|)([1357])\/([248]|16)SM$/) # US
        miles          = $1.to_f + $3.to_f / $4.to_f
        distance       = Distance.miles( miles )
        distance.units = :miles
        new( distance )
      when s =~ /^(\d+)SM$/ # US
        distance       = Distance.miles( $1.to_f )
        distance.units = :miles
        new( distance )
      when s == 'M1/4SM' # US
        distance       = Distance.miles( 0.25 )
        distance.units = :miles
        new( distance, nil, :less_than )
      when s =~ /^(\d+)KM$/
        new( Distance.kilometers( $1 ) )
      when s =~ /^(\d+)$/ # We assume meters
        new( Distance.new( $1 ) )
      when s =~ /^(\d+)(N|NE|E|SE|S|SW|W|NW)$/
        new( Distance.meters( $1 ), M9t::Direction.compass( $2 ) )
      else
        nil
      end
    end

    attr_reader :distance, :direction, :comparator

    def initialize(distance, direction = nil, comparator = nil)
      @distance, @direction, @comparator = distance, direction, comparator
    end

    def to_s( options = {} )
      distance_options = { :abbreviated => true,
                           :precision   => 0,
                           :units       => :kilometers }.merge( options )
      direction_options = { :units => :compass }
      case
      when ( @direction.nil? and @comparator.nil? )
        @distance.to_s( distance_options )
      when @comparator.nil?
        "%s %s" % [ @distance.to_s( distance_options ),
                    @direction.to_s( direction_options ) ]
      when @direction.nil?
        "%s %s" % [ I18n.t( 'comparison.' + @comparator.to_s ),
                    @distance.to_s( distance_options ) ]
      else
        "%s %s %s" % [ I18n.t( 'comparison.' + @comparator.to_s ),
                       @distance.to_s( distance_options ),
                       @direction.to_s( direction_options ) ]
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
        distance   = Distance.send( units, count )
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
        distance1   = Distance.send( units, count1 )
        distance2   = Distance.send( units, count2 )
        visibility1 = Visibility.new( distance1, nil, comparator1 )
        visibility2 = Visibility.new( distance2, nil, comparator2 )
        new( designator, visibility1, visibility2, tendency, units )
      else
        nil
      end
    end

    attr_reader :designator, :visibility1, :visibility2, :tendency
    def initialize( designator, visibility1, visibility2 = nil, tendency = nil, units = :meters )
      @designator, @visibility1, @visibility2, @tendency, @units = designator, visibility1, visibility2, tendency, units
    end

    def to_s
      distance_options = { :abbreviated => true,
                           :precision   => 0,
                           :units       => @units }
      s =
        if @visibility2.nil?
          I18n.t( 'metar.runway_visible_range.runway') +
                  ' '  + @designator +
                  ': ' + @visibility1.to_s( distance_options )
        else
          I18n.t( 'metar.runway_visible_range.runway') +
                  ' '  + @designator +
                  ': ' + I18n.t('metar.runway_visible_range.from') +
                  ' '  + @visibility1.to_s( distance_options ) +
                  ' '  + I18n.t('metar.runway_visible_range.to') +
                  ' '  + @visibility2.to_s( distance_options )
        end

      if ! tendency.nil?
        s += ' ' + I18n.t( "tendency.#{ tendency }" )
      end

      s
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
      I18n.t("metar.present_weather.%s" % [@modifier, @descriptor, @phenomenon].compact.join(' '))
    end

  end

  class SkyCondition

    QUANTITY = {'BKN' => 'broken', 'FEW' => 'few', 'OVC' => 'overcast', 'SCT' => 'scattered'}
    CONDITION = {
      'CB'  => 'cumulonimbus',
      'TCU' => 'towering cumulus',
      '///' => nil, # cloud type unknown as observed by automatic system (15.9.1.7)
      ''    => nil
    }
    CLEAR_SKIES = [
      'NSC', # WMO
      'NCD', # WMO
      'CLR',
      'SKC',
    ]

    def SkyCondition.parse(sky_condition)
      case
      when CLEAR_SKIES.include?( sky_condition )
        new
      when sky_condition =~ /^(BKN|FEW|OVC|SCT)(\d+|\/{3})(CB|TCU|\/{3}|)?$/
        quantity = QUANTITY[ $1 ]
        height   =
          if $2 == '///'
            nil
          else
            Distance.new( $2.to_i * 30.48 )
          end
        type = CONDITION[ $3 ]
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
        I18n.t("metar.sky_conditions.#{ @quantity }#{ type }")
      end
    end

  end

  class VerticalVisibility

    def VerticalVisibility.parse( vertical_visibility )
      case
      when vertical_visibility =~ /^VV(\d{3})$/
        Distance.new( $1.to_f * 30.48 )
      when vertical_visibility == '///'
        Distance.new
      else
        nil
      end
    end

  end

end

