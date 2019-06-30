# frozen_string_literal: true

require "i18n"
require "m9t"

module Metar
  module Data
    TemperatureExtreme = Struct.new(:raw, :extreme, :value)
    PressureTendency = Struct.new(:raw, :character, :value)
    Precipitation = Struct.new(:raw, :period, :amount)
    AutomatedStationType = Struct.new(:raw, :type)
    HourlyTemperatureAndDewPoint = Struct.new(:raw, :temperature, :dew_point)
    SeaLevelPressure = Struct.new(:raw, :pressure)
    SensorStatusIndicator = Struct.new(:raw, :type, :state)
    ColorCode = Struct.new(:raw, :code)
    MaintenanceNeeded = Struct.new(:raw)

    class Remark
      PRESSURE_CHANGE_CHARACTER = [
        :increasing_then_decreasing, # 0
        :increasing_then_steady,     # 1
        :increasing,                 # 2
        :decreasing_or_steady_then_increasing, # 3
        :steady,                     # 4
        :decreasing_then_increasing, # 5
        :decreasing_then_steady,     # 6
        :decreasing,                 # 7
        :steady_then_decreasing # 8
      ].freeze

      INDICATOR_TYPE = {
        'TS' => :thunderstorm_information,
        'PWI' => :precipitation_identifier,
        'P' => :precipitation_amount
      }.freeze

      COLOR_CODE = %w(RED AMB YLO GRN WHT BLU).freeze

      def self.parse(raw)
        return nil if !raw

        m1 = raw.match(/^([12])([01])(\d{3})$/)
        if m1
          extreme = {'1' => :maximum, '2' => :minimum}[m1[1]]
          value   = sign(m1[2]) * tenths(m1[3])
          return Metar::Data::TemperatureExtreme.new(raw, extreme, value)
        end

        m2 = raw.match(/^4([01])(\d{3})([01])(\d{3})$/)
        if m2
          v1 = sign(m2[1]) * tenths(m2[2])
          v2 = sign(m2[3]) * tenths(m2[4])
          return [
            Metar::Data::TemperatureExtreme.new(raw, :maximum, v1),
            Metar::Data::TemperatureExtreme.new(raw, :minimum, v2)
          ]
        end

        m3 = raw.match(/^5([0-8])(\d{3})$/)
        if m3
          character = PRESSURE_CHANGE_CHARACTER[m3[1].to_i]
          return Metar::Data::PressureTendency.new(
            raw, character, tenths(m3[2])
          )
        end

        m4 = raw.match(/^6(\d{4})$/)
        if m4
          d = Metar::Data::Distance.new(inches_to_meters(m4[1]))
          period = 3 # actually 3 or 6 depending on reporting time
          return Metar::Data::Precipitation.new(raw, period, d)
        end

        m5 = raw.match(/^7(\d{4})$/)
        if m5
          d = Metar::Data::Distance.new(inches_to_meters(m5[1]))
          return Metar::Data::Precipitation.new(raw, 24, d)
        end

        m6 = raw.match(/^A[0O]([12])$/)
        if m6
          index = m6[1].to_i - 1
          type = %i(
            with_precipitation_discriminator without_precipitation_discriminator
          )[index]
          return Metar::Data::AutomatedStationType.new(raw, type)
        end

        m7 = raw.match(/^P(\d{4})$/)
        if m7
          d = Metar::Data::Distance.new(inches_to_meters(m7[1]))
          return Metar::Data::Precipitation.new(raw, 1, d)
        end

        m8 = raw.match(/^T([01])(\d{3})([01])(\d{3})$/)
        if m8
          temperature = Metar::Data::Temperature.new(
            sign(m8[1]) * tenths(m8[2])
          )
          dew_point = Metar::Data::Temperature.new(
            sign(m8[3]) * tenths(m8[4])
          )
          return Metar::Data::HourlyTemperatureAndDewPoint.new(
            raw, temperature, dew_point
          )
        end

        m9 = raw.match(/^SLP(\d{3})$/)
        if m9
          pressure = M9t::Pressure.hectopascals(tenths(m9[1]))
          return Metar::Data::SeaLevelPressure.new(raw, pressure)
        end

        m10 = raw.match(/^(#{INDICATOR_TYPE.keys.join('|')})NO$/)
        if m10
          type = INDICATOR_TYPE[m10[1]]
          return Metar::Data::SensorStatusIndicator.new(
            raw, type, :not_available
          )
        end

        m11 = raw.match(/^(#{COLOR_CODE.join('|')})$/)
        return Metar::Data::ColorCode.new(raw, m11[1]) if m11

        return Metar::Data::SkyCondition.new(raw) if raw == 'SKC'

        return Metar::Data::MaintenanceNeeded.new(raw) if raw == '$'

        nil
      end

      def self.sign(digit)
        case digit
        when '0'
          1.0
        when '1'
          -1.0
        else
          raise "Unexpected sign: #{digit}"
        end
      end

      def self.tenths(digits)
        digits.to_f / 10.0
      end

      def self.inches_to_meters(digits)
        digits.to_f * 0.000254
      end
    end
  end
end
