# frozen_string_literal: true

module Metar
  module Data
    class Pressure < Metar::Data::Base
      def self.parse(raw)
        return nil if raw.nil?

        m1 = raw.match(/^Q(\d{4})$/)
        if m1
          pressure = M9t::Pressure.hectopascals(m1[1].to_f)
          return new(raw, pressure: pressure)
        end

        m2 = raw.match(/^A(\d{4})$/)
        if m2
          pressure = M9t::Pressure.inches_of_mercury(m2[1].to_f / 100.0)
          return new(raw, pressure: pressure)
        end

        nil
      end

      attr_reader :pressure

      def initialize(raw, pressure:)
        @raw = raw
        @pressure = pressure
      end

      def value
        pressure.value
      end
    end
  end
end
