module Metar

  class Temperature
    
    attr_reader :value, :unit
    def initialize(s)
      @unit = :celcius
      if s =~ /^(M?)(\d+)$/
        sign = $1
        @value = $2.to_i
        @value *= -1 if sign == 'M'
      else
        @value = nil
      end
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

    alias :value :to_s
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
      '-' => 'light ',
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
      'SH' => 'shower', # only US?
      'SN' => 'snow',
      'SG' => 'snow grains',
      'SNRA' => 'snow and rain',
      'SQ' => 'squall',
      'UP' => 'unknown phenomenon',
      'VA' => 'volcanic ash',
      'FC' => 'funnel cloud',
      'SS' => 'sand storm',
      'DS' => 'dust storm',
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
      when (s == 'NSC' or s == 'NCD') # WMO
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

end
