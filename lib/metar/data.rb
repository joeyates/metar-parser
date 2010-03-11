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
      units = :degrees
      if s =~ /^(M?)(\d+)$/
        sign = $1
        value = $2.to_i
        value *= -1 if sign == 'M'
        new(value, :units => units)
      else
        nil
      end
    end

  end

  class Visibility

    def Visibility.parse(s)
      case
      when s == '9999'
        new(M9t::Distance.new(10000, {:units => :kilometers, :precision => 0}), nil, :more_than)
      when s =~ /(\d{4})NDV/ # WMO
        new(M9t::Distance.new($1.to_f)) # Assuming meters
      when (s =~ /^((1|2)\s|)([13])\/([24])SM$/) # US
        miles = $1.to_f + $3.to_f / $4.to_f
        new(M9t::Distance.miles(miles, {:units => :miles}))
      when s =~ /^(\d+)SM$/ # US
        new(M9t::Distance.miles($1.to_f, {:units => :miles}))
      when s == 'M1/4SM' # US
        new(M9t::Distance.miles(0.25, {:units => :miles}), nil, :less_than)
      when s =~ /^(\d+)KM$/
        new(M9t::Distance.kilometers($1, {:units => :kilometers}))
      when s =~ /^(\d+)(N|NE|E|SE|S|SW|W|NW)?$/
        new(M9t::Distance.kilometers($1, {:units => :kilometers}), M9t::Direction.compass($2))
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

  class WeatherPhenomenon

    Modifiers = {
      '\+' => 'heavy ',
      '-'  => 'light ',
      'VC' => 'nearby '
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
      'PY'   => '???', # TODO
      'RA'   => 'rain',
      'SA'   => 'sand',
      'SH'   => 'shower', # only US?
      'SN'   => 'snow',
      'SG'   => 'snow grains',
      'SNRA' => 'snow and rain',
      'SQ'   => 'squall',
      'UP'   => 'unknown phenomenon',
      'VA'   => 'volcanic ash',
      'FC'   => 'funnel cloud',
      'SS'   => 'sand storm',
      'DS'   => 'dust storm',
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

    def initialize(phenomenon, modifier = nil, descriptor = nil)
      @phenomenon, @modifier, @descriptor = phenomenon, modifier, descriptor
    end

    def to_s
      "#{ @modifier }#{ @descriptor }#{ @phenomenon }"
    end

  end

  class SkyCondition

    def SkyCondition.parse(s)
      case
      when (s == 'NSC' or s == 'NCD') # WMO
        'No significant cloud'
      when s == 'CLR'
        'Clear skies'
      when s == 'SKC'
        'Clear skies'
      when s =~ /^(BKN|FEW|OVC|SCT)(\d+)(CB|TCU|\/{3})?$/
        quantity = $1
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
        case quantity
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

end
