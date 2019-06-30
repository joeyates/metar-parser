# frozen_string_literal: true

require "i18n"
require "m9t"

module Metar
  module Data
    class Speed < M9t::Speed
      METAR_UNITS = {
        "" => :kilometers_per_hour,
        "KMH" => :kilometers_per_hour,
        "MPS" => :meters_per_second,
        "KT" => :knots
      }.freeze

      def self.parse(raw)
        return nil if raw.nil?

        m = raw.match(/^(\d+)(|KT|MPS|KMH)$/)
        return nil if m.nil?

        # Call the appropriate factory method for the supplied units
        send(METAR_UNITS[m[2]], m[1].to_i)
      end
    end
  end
end
