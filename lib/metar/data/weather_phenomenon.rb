# frozen_string_literal: true

require "metar/i18n"

module Metar
  module Data
    class WeatherPhenomenon < Metar::Data::Base
      MODIFIERS = {
        '+' => 'heavy',
        '-' => 'light',
        'VC' => 'nearby',
        '-VC' => 'nearby light',
        '+VC' => 'nearby heavy'
      }.freeze

      DESCRIPTORS = {
        'BC' => 'patches of',
        'BL' => 'blowing',
        'DR' => 'low drifting',
        'FZ' => 'freezing',
        'MI' => 'shallow',
        'PR' => 'partial',
        'SH' => 'shower of',
        'TS' => 'thunderstorm and'
      }.freeze

      PHENOMENA = {
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
        'PY' => 'spray', # US only
        'RA' => 'rain',
        'SA' => 'sand',
        'SH' => 'shower',
        'SN' => 'snow',
        'SG' => 'snow grains',
        'SQ' => 'squall',
        'UP' => 'unknown phenomenon', # => AUTO
        'VA' => 'volcanic ash',
        'FC' => 'funnel cloud',
        'SS' => 'sand storm',
        'DS' => 'dust storm',
        'TS' => 'thunderstorm'
      }.freeze

      # Accepts all standard (and some non-standard) present weather codes
      def self.parse(raw)
        modifiers = MODIFIERS.keys.join('|')
        modifiers.gsub!(/([\+\-])/) { |m| "\\#{m}" }

        descriptors = DESCRIPTORS.keys.join('|')

        phenomena = PHENOMENA.keys.join('|')

        rxp = Regexp.new(
          "^(RE)?(#{modifiers})?(#{descriptors})?((?:#{phenomena}){1,2})$"
        )

        m = rxp.match(raw)
        return nil if m.nil?

        recent = m[1] == "RE"
        modifier_code = m[2]
        descriptor_code = m[3]
        phenomena_codes = m[4].scan(/../)
        phenomena = phenomena_codes.map { |c| PHENOMENA[c] }
        phenomena_phrase = phenomena.join(' and ')

        new(
          raw,
          phenomenon: phenomena_phrase,
          modifier: MODIFIERS[modifier_code],
          descriptor: DESCRIPTORS[descriptor_code],
          recent: recent
        )
      end

      attr_reader :phenomenon, :modifier, :descriptor, :recent

      def initialize(
        raw, phenomenon:, modifier: nil, descriptor: nil, recent: false
      )
        @raw = raw
        @phenomenon = phenomenon
        @modifier = modifier
        @descriptor = descriptor
        @recent = recent
      end

      def to_s
        key = [modifier, descriptor, phenomenon].compact.join(' ')
        I18n.t("metar.present_weather.#{key}")
      end
    end
  end
end
