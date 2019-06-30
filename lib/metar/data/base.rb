# frozen_string_literal: true

module Metar
  module Data
    class Base
      def self.parse(raw)
        new(raw)
      end

      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      def value
        raw
      end
    end
  end
end
