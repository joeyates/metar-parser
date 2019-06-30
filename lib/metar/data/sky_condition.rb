# frozen_string_literal: true

module Metar
  module Data
    class SkyCondition < Metar::Data::Base
      QUANTITY = {
        'BKN' => 'broken',
        'FEW' => 'few',
        'OVC' => 'overcast',
        'SCT' => 'scattered'
      }.freeze

      CONDITION = {
        'CB' => 'cumulonimbus',
        'TCU' => 'towering cumulus',
        # /// - cloud type unknown as observed by automatic system (15.9.1.7)
        '///' => nil,
        '' => nil
      }.freeze
      CLEAR_SKIES = [
        'NSC', # WMO
        'NCD', # WMO
        'CLR',
        'SKC'
      ].freeze

      def self.parse(raw)
        return nil if !raw

        return new(raw) if CLEAR_SKIES.include?(raw)

        m1 = raw.match(%r{^(BKN|FEW|OVC|SCT)(\d+|/{3})(CB|TCU|/{3}|)?$})
        if m1
          quantity = QUANTITY[m1[1]]
          height   =
            if m1[2] == '///'
              nil
            else
              Metar::Data::Distance.new(m1[2].to_i * 30.48)
            end
          type = CONDITION[m1[3]]
          return new(raw, quantity: quantity, height: height, type: type)
        end

        m2 = raw.match(/^(CB|TCU)$/)
        if m2
          type = CONDITION[m2[1]]
          return new(raw, type: type)
        end

        nil
      end

      attr_reader :quantity, :height, :type

      def initialize(raw, quantity: nil, height: nil, type: nil)
        @raw = raw
        @quantity = quantity
        @height = height
        @type = type
      end

      def to_s
        if @height.nil?
          to_summary
        else
          to_summary + ' ' + I18n.t('metar.altitude.at') + ' ' + height.to_s
        end
      end

      def to_summary
        if @quantity.nil? && @height.nil? && @type.nil?
          I18n.t('metar.sky_conditions.clear skies')
        else
          type = @type ? ' ' + @type : ''
          I18n.t("metar.sky_conditions.#{@quantity}#{type}")
        end
      end
    end
  end
end
