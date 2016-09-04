require "i18n"
require "m9t"

class Metar::Data::Remark
  PRESSURE_CHANGE_CHARACTER = [
    :increasing_then_decreasing, # 0
    :increasing_then_steady,     # 1
    :increasing,                 # 2
    :decreasing_or_steady_then_increasing, # 3
    :steady,                     # 4
    :decreasing_then_increasing, # 5
    :decreasing_then_steady,     # 6
    :decreasing,                 # 7
    :steady_then_decreasing,     # 8
  ]

  INDICATOR_TYPE = {
    'TS'  => :thunderstorm_information,
    'PWI' => :precipitation_identifier,
    'P'   => :precipitation_amount,
  }

  COLOR_CODE = ['RED', 'AMB', 'YLO', 'GRN', 'WHT', 'BLU']

  def self.parse(raw)
    case raw
    when /^([12])([01])(\d{3})$/
      extreme = {'1' => :maximum, '2' => :minimum}[$1]
      value   = sign($2) * tenths($3)
      Metar::Data::TemperatureExtreme.new(raw, extreme, value)
    when /^4([01])(\d{3})([01])(\d{3})$/
      [
        Metar::Data::TemperatureExtreme.new(raw, :maximum, sign($1) * tenths($2)),
        Metar::Data::TemperatureExtreme.new(raw, :minimum, sign($3) * tenths($4)),
      ]
    when /^5([0-8])(\d{3})$/
      character = PRESSURE_CHANGE_CHARACTER[$1.to_i]
      Metar::Data::PressureTendency.new(raw, character, tenths($2))
    when /^6(\d{4})$/
      Metar::Data::Precipitation.new(raw, 3, Metar::Data::Distance.new(inches_to_meters($1))) # actually 3 or 6 depending on reporting time
    when /^7(\d{4})$/
      Metar::Data::Precipitation.new(raw, 24, Metar::Data::Distance.new(inches_to_meters($1)))
    when /^A[0O]([12])$/
      type = [:with_precipitation_discriminator, :without_precipitation_discriminator][$1.to_i - 1]
      Metar::Data::AutomatedStationType.new(raw, type)
    when /^P(\d{4})$/
      Metar::Data::Precipitation.new(raw, 1, Metar::Data::Distance.new(inches_to_meters($1)))
    when /^T([01])(\d{3})([01])(\d{3})$/
      temperature = Metar::Data::Temperature.new(sign($1) * tenths($2))
      dew_point   = Metar::Data::Temperature.new(sign($3) * tenths($4))
      Metar::Data::HourlyTemperatureAndDewPoint.new(raw, temperature, dew_point)
    when /^SLP(\d{3})$/
      Metar::Data::SeaLevelPressure.new(raw, M9t::Pressure.hectopascals(tenths($1)))
    when /^(#{INDICATOR_TYPE.keys.join('|')})NO$/
      type = INDICATOR_TYPE[$1]
      Metar::Data::SensorStatusIndicator.new(raw, :type, :not_available)
    when /^(#{COLOR_CODE.join('|')})$/
      Metar::Data::ColorCode.new(raw, $1)
    when 'SKC'
      Metar::Data::SkyCondition.new(raw)
    when '$'
      Metar::Data::MaintenanceNeeded.new(raw)
    else
      nil
    end
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

module Metar::Data
  TemperatureExtreme = Struct.new(:raw, :extreme, :value)
  PressureTendency = Struct.new(:raw, :character, :value)
  Precipitation = Struct.new(:raw, :period, :amount)
  AutomatedStationType = Struct.new(:raw, :type)
  HourlyTemperatureAndDewPoint = Struct.new(:raw, :temperature, :dew_point)
  SeaLevelPressure = Struct.new(:raw, :pressure)
  SensorStatusIndicator = Struct.new(:raw, :type, :state)
  ColorCode = Struct.new(:raw, :code)
  MaintenanceNeeded = Struct.new(:raw)
end
