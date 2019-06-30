# frozen_string_literal: true

module Metar
  module Data
    class TemperatureAndDewPoint < Metar::Data::Base
      def self.parse(raw)
        return nil if !raw

        m = raw.match(%r{^(M?\d+|XX|//)\/(M?\d+|XX|//)?$})
        return nil if !m

        temperature = Metar::Data::Temperature.parse(m[1])
        dew_point = Metar::Data::Temperature.parse(m[2])
        new(raw, temperature: temperature, dew_point: dew_point)
      end

      attr_reader :temperature
      attr_reader :dew_point

      def initialize(raw, temperature:, dew_point:)
        @raw = raw
        @temperature = temperature
        @dew_point = dew_point
      end
    end
  end
end
