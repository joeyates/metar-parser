# frozen_string_literal: true

module Metar
  module Data
    class RunwayVisibleRange < Metar::Data::Base
      TENDENCY = {
        '' => nil,
        'N' => :no_change,
        'U' => :improving,
        'D' => :worsening
      }.freeze

      COMPARATOR = {'' => nil, 'P' => :more_than, 'M' => :less_than}.freeze
      UNITS      = {'' => :meters, 'FT' => :feet}.freeze

      def self.parse(raw)
        return nil if raw.nil?

        m1 = raw.match(%r{^R(\d+[RLC]?)/(P|M|)(\d{4})(FT|)/?(N|U|D|)$})
        if m1
          designator = m1[1]
          comparator = COMPARATOR[m1[2]]
          count      = m1[3].to_f
          units      = UNITS[m1[4]]
          tendency   = TENDENCY[m1[5]]
          distance   = Metar::Data::Distance.send(units, count)
          visibility = Metar::Data::Visibility.new(
            nil, distance: distance, comparator: comparator
          )
          return new(
            raw,
            designator: designator, visibility1: visibility, tendency: tendency
          )
        end

        m2 = raw.match(
          %r{^R(\d+[RLC]?)/(P|M|)(\d{4})V(P|M|)(\d{4})(FT|)/?(N|U|D)?$}
        )
        if m2
          designator  = m2[1]
          comparator1 = COMPARATOR[m2[2]]
          count1      = m2[3].to_f
          comparator2 = COMPARATOR[m2[4]]
          count2      = m2[5].to_f
          units       = UNITS[m2[6]]
          tendency    = TENDENCY[m2[7]]
          distance1   = Metar::Data::Distance.send(units, count1)
          distance2   = Metar::Data::Distance.send(units, count2)
          visibility1 = Metar::Data::Visibility.new(
            nil, distance: distance1, comparator: comparator1
          )
          visibility2 = Metar::Data::Visibility.new(
            nil, distance: distance2, comparator: comparator2
          )
          return new(
            raw,
            designator: designator,
            visibility1: visibility1, visibility2: visibility2,
            tendency: tendency, units: units
          )
        end

        nil
      end

      attr_reader :designator, :visibility1, :visibility2, :tendency

      def initialize(
        raw,
        designator:,
        visibility1:,
        visibility2: nil,
        tendency: nil,
        units: :meters
      )
        @raw = raw
        @designator = designator
        @visibility1 = visibility1
        @visibility2 = visibility2
        @tendency = tendency
        @units = units
      end

      def to_s
        distance_options = {
          abbreviated: true,
          precision: 0,
          units: @units
        }
        s =
          if @visibility2.nil?
            I18n.t('metar.runway_visible_range.runway') +
              ' '  + @designator +
              ': ' + @visibility1.to_s(distance_options)
          else
            I18n.t('metar.runway_visible_range.runway') +
              ' '  + @designator +
              ': ' + I18n.t('metar.runway_visible_range.from') +
              ' '  + @visibility1.to_s(distance_options) +
              ' '  + I18n.t('metar.runway_visible_range.to') +
              ' '  + @visibility2.to_s(distance_options)
          end

        s += ' ' + I18n.t("tendency.#{tendency}") if !tendency.nil?

        s
      end
    end
  end
end
