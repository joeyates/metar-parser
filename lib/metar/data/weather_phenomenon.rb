require "metar/i18n"

class Metar::Data::WeatherPhenomenon < Metar::Data::Base
  Modifiers = {
    '+'   => 'heavy',
    '-'   => 'light',
    'VC'  => 'nearby',
    '-VC' => 'nearby light',
    '+VC' => 'nearby heavy',
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
    'SQ'   => 'squall',
    'UP'   => 'unknown phenomenon', # => AUTO
    'VA'   => 'volcanic ash',
    'FC'   => 'funnel cloud',
    'SS'   => 'sand storm',
    'DS'   => 'dust storm',
    'TS'   => 'thunderstorm',
  }

  # Accepts all standard (and some non-standard) present weather codes
  def self.parse(raw)
    phenomena   = Phenomena.keys.join('|')
    descriptors = Descriptors.keys.join('|')
    modifiers   = Modifiers.keys.join('|')
    modifiers.gsub!(/([\+\-])/) { |m| "\\#{m}" }
    rxp = Regexp.new("^(RE)?(#{modifiers})?(#{descriptors})?((?:#{phenomena}){1,2})$")
    m   = rxp.match(raw)
    return nil if m.nil?

    recent           = m[1] == "RE"
    modifier_code    = m[2]
    descriptor_code  = m[3]
    phenomena_codes  = m[4].scan(/../)
    phenomena_phrase = phenomena_codes.map { |c| Phenomena[c] }.join(' and ')

    new(
      raw,
      phenomenon: phenomena_phrase,
      modifier: Modifiers[modifier_code],
      descriptor: Descriptors[descriptor_code]
    )
  end

  attr_reader :phenomenon, :modifier, :descriptor, :recent

  def initialize(raw, phenomenon:, modifier: nil, descriptor: nil, recent: false)
    @raw = raw
    @phenomenon, @modifier, @descriptor = phenomenon, modifier, descriptor
    @recent = recent
  end

  def to_s
    key = [modifier, descriptor, phenomenon].compact.join(' ')
    I18n.t("metar.present_weather.%s" % key)
  end
end
