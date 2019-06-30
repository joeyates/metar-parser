# frozen_string_literal: true

require "i18n"
require "m9t"

module Metar
  module Data
    class Temperature < M9t::Temperature
      def self.parse(raw)
        return nil if !raw

        m = raw.match(/^(M?)(\d+)$/)
        return nil if !m

        sign = m[1]
        value = m[2].to_i
        value *= -1 if sign == 'M'
        new(value)
      end

      def to_s(options = {})
        options = {abbreviated: true, precision: 0}.merge(options)
        super(options)
      end
    end
  end
end
