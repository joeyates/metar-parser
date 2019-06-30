# frozen_string_literal: true

module Metar
  module Data
    class Visibility < Metar::Data::Base
      def self.parse(raw)
        return nil if !raw

        if raw == '9999'
          return new(
            raw,
            distance: Metar::Data::Distance.new(10_000),
            comparator: :more_than
          )
        end

        m1 = raw.match(/(\d{4})NDV/) # WMO
        if m1
          return new(
            raw, distance: Metar::Data::Distance.new(m1[1].to_f)
          ) # Assuming meters
        end

        m2 = raw.match(%r{^((1|2)\s|)([1357])/([248]|16)SM$}) # US
        if m2
          numerator = m2[3].to_f
          denominator = m2[4].to_f
          miles = m2[1].to_f + numerator / denominator
          distance = Metar::Data::Distance.miles(miles)
          distance.serialization_units = :miles
          return new(raw, distance: distance)
        end

        m3 = raw.match(/^(\d+)SM$/) # US
        if m3
          distance = Metar::Data::Distance.miles(m3[1].to_f)
          distance.serialization_units = :miles
          return new(raw, distance: distance)
        end

        if raw == 'M1/4SM' # US
          distance = Metar::Data::Distance.miles(0.25)
          distance.serialization_units = :miles
          return new(raw, distance: distance, comparator: :less_than)
        end

        m4 = raw.match(/^(\d+)KM$/)
        return new(raw, distance: Metar::Data::Distance.kilometers(m4[1])) if m4

        m5 = raw.match(/^(\d+)$/) # We assume meters
        return new(raw, distance: Metar::Data::Distance.new(m5[1])) if m5

        m6 = raw.match(/^(\d+)(N|NE|E|SE|S|SW|W|NW)$/)
        if m6
          return new(
            raw,
            distance: Metar::Data::Distance.meters(m6[1]),
            direction: M9t::Direction.compass(m6[2])
          )
        end

        nil
      end

      attr_reader :distance, :direction, :comparator

      def initialize(raw, distance:, direction: nil, comparator: nil)
        @raw = raw
        @distance = distance
        @direction = direction
        @comparator = comparator
      end

      def to_s(options = {})
        distance_options = {
          abbreviated: true,
          precision: 0,
          units: :kilometers
        }.merge(options)

        direction_options = {units: :compass}

        case
        when @direction.nil? && @comparator.nil?
          @distance.to_s(distance_options)
        when @comparator.nil?
          [
            @distance.to_s(distance_options),
            @direction.to_s(direction_options)
          ].join(' ')
        when @direction.nil?
          [
            I18n.t('comparison.' + @comparator.to_s),
            @distance.to_s(distance_options)
          ].join(' ')
        else
          [
            I18n.t('comparison.' + @comparator.to_s),
            @distance.to_s(distance_options),
            @direction.to_s(direction_options)
          ].join(' ')
        end
      end
    end
  end
end
