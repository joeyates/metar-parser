# frozen_string_literal: true

module Metar
  module Data
    class Observer < Metar::Data::Base
      def self.parse(raw)
        case
        when raw == 'AUTO' # WMO 15.4
          new(raw, value: :auto)
        when raw == 'COR'  # WMO specified code word for correction
          new(raw, value: :corrected)
        when raw =~ /CC[A-Z]/ # Canadian correction
          # Canada uses CCA for first correction, CCB for second, etc...
          new(raw, value: :corrected)
        when raw == 'RTD' #  Delayed observation, no comments on observer
          new(raw, value: :rtd)
        else
          new(nil, value: :real)
        end
      end

      attr_reader :value

      def initialize(raw, value:)
        @raw = raw
        @value = value
      end
    end
  end
end
