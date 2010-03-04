module Metar

  class Temperature
    
    attr_reader :value, :unit
    def Temperature.parse(s)
      unit = :celcius
      if s =~ /^(M?)(\d+)$/
        sign = $1
        value = $2.to_i
        value *= -1 if sign == 'M'
        new(value, unit)
      else
        nil
      end
    end

    def initialize(value, unit = :celcius)
      @value, @unit = value, unit
    end

    def to_s
      @value ? "#{ @value }&deg;" : 'Not available'
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
        nil
      end
    end

    attr_reader :value, :unit
    def initialize(value, unit = :kilometers_per_hour)
      @value, @unit = value, unit
    end

    def to_s
      "#{ @value } #{ @unit }"
    end

  end

  class Visibility

    DIRECTION = {
      'N'   => 0,
      'NE'  => 45,
      'E'   => 90,
      'SE'  => 135,
      'S'   => 180,
      'SW'  => 225,
      'W'   => 270,
      'NW'  => 315,
    }

    def Visibility.parse(s)
      case
      when s == '9999'
        new(Distance.new(10, :kilometer), nil, :more)
      when s =~ /(\d{4})NDV/ # WMO
        new(Distance.new($1.to_f))
      when (s =~ /^((1|2)\s|)([13])\/([24])SM$/) # US
        miles = $1.to_f + $3.to_f / $4.to_f
        new(Distance.new(miles, :mile))
      when s =~ /^(\d+)SM$/ # US
        new(Distance.new($1, :mile))
      when s == 'M1/4SM' # US
        new(Distance.new(0.25, :mile), nil, :less)
      when s =~ /^(\d+)KM$/
        new(Distance.new($1.to_f, :kilometer))
      when s =~ /^(\d+)(N|NE|E|SE|S|SW|W|NW)?$/
        direction = DIRECTION[$2]
        new(Distance.new($1.to_f, :kilometer), direction)
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
        "%s %s" % [@distance.to_s, direction_s]
      when @direction.nil?
        "%s %s" % [comparator_s, @distance.to_s]
      else
        "%s %s %s" % [comparator_s, @distance.to_s, direction_s]
      end
    end

    private

    def comparator_s
      comparator = {:more => 'more than', :less => 'less than'}[@comparator]
    end

    def direction_s
      "%u&deg;" % @direction
    end
  end

  class Distance

    attr_reader :value, :unit

    def initialize(value, unit = :meter)
      @value, @unit = value, unit
    end

    def to_s
      unit = @value == 1 ? @unit.to_s : "#{ @unit.to_s }s"
      "#{ @value } #{ unit }"
    end

  end

  class Wind

    def Wind.parse(s)
      case
      when s =~ /^(\d{3})(\d{2}(KT|MPS|KMH|))$/
        new("#$1&deg", Speed.parse($2))
      when s =~ /^(\d{3})(\d{2})G(\d{2,3}(KT|MPS|KMH|))$/
        new("#$1&deg", Speed.parse($2)) # TODO
      when s =~ /^VRB(\d{2}(KT|MPS|KMH|))$/
        new('variable direction', Speed.parse($2))
      when s =~ /^\/{3}(\d{2}(KT|MPS|KMH|))$/
        new('unknown direction', Speed.parse($2))
      when s =~ /^\/{3}(\/{2}(KT|MPS|KMH|))$/
        new('unknown direction', 'unknown')
      else
        nil
      end
    end

    attr_reader :direction, :speed, :units
    def initialize(direction, speed, units = :kmh)
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
      when s == 'CLR' # TODO - meaning?
        'Clear skies'
      when s == 'SKC' # TODO - meaning?
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
