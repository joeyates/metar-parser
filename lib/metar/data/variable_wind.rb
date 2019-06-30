# frozen_string_literal: true

module Metar
  module Data
    class VariableWind < Metar::Data::Base
      def self.parse(raw)
        return nil if raw.nil?

        m = raw.match(/^(\d+)V(\d+)$/)
        return nil if m.nil?

        new(
          raw,
          direction1: Metar::Data::Direction.new(m[1]),
          direction2: Metar::Data::Direction.new(m[2])
        )
      end

      attr_reader :direction1
      attr_reader :direction2

      def initialize(raw, direction1:, direction2:)
        @raw = raw
        @direction1 = direction1
        @direction2 = direction2
      end

      def to_s
        format(
          "%<direction1>s - %<direction2>s",
          direction1: direction1.to_s(units: :compass),
          direction2: direction2.to_s(units: :compass)
        )
      end
    end
  end
end
