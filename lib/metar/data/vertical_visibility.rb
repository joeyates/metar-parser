# frozen_string_literal: true

require "i18n"
require "m9t"

module Metar
  module Data
    class VerticalVisibility < Metar::Data::Base
      def self.parse(raw)
        return nil if !raw

        m1 = raw.match(/^VV(\d{3})$/)
        if m1
          return new(
            raw,
            distance: Metar::Data::Distance.new(m1[1].to_f * 30.48)
          )
        end

        return new(raw, distance: Metar::Data::Distance.new) if raw == '///'

        nil
      end

      attr_reader :distance

      def initialize(raw, distance:)
        @raw = raw
        @distance = distance
      end

      def value
        distance.value
      end
    end
  end
end
