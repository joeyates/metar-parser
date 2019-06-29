# frozen_string_literal: true

class Metar::Data::Visibility < Metar::Data::Base
  def self.parse(raw)
    if !raw
      return nil
    end

    if raw == '9999'
      return new(
        raw, distance: Metar::Data::Distance.new(10000), comparator: :more_than
      )
    end

    m1 = raw.match(/(\d{4})NDV/) # WMO
    if m1
      return new(
        raw, distance: Metar::Data::Distance.new(m1[1].to_f)
      ) # Assuming meters
    end

    m2 = raw.match(/^((1|2)\s|)([1357])\/([248]|16)SM$/) # US
    if m2
      miles          = m2[1].to_f + m2[3].to_f / m2[4].to_f
      distance       = Metar::Data::Distance.miles(miles)
      distance.serialization_units = :miles
      return new(raw, distance: distance)
    end

    m3 = raw.match(/^(\d+)SM$/) # US
    if m3
      distance       = Metar::Data::Distance.miles(m3[1].to_f)
      distance.serialization_units = :miles
      return new(raw, distance: distance)
    end

    if raw == 'M1/4SM' # US
      distance       = Metar::Data::Distance.miles(0.25)
      distance.serialization_units = :miles
      return new(raw, distance: distance, comparator: :less_than)
    end

    m4 = raw.match(/^(\d+)KM$/)
    if m4
      return new(raw, distance: Metar::Data::Distance.kilometers(m4[1]))
    end

    m5 = raw.match(/^(\d+)$/) # We assume meters
    if m5
      return new(raw, distance: Metar::Data::Distance.new(m5[1]))
    end

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
    @distance, @direction, @comparator = distance, direction, comparator
  end

  def to_s(options = {})
    distance_options = {
      abbreviated: true,
      precision:   0,
      units:       :kilometers,
    }.merge(options)
    direction_options = {units: :compass}
    case
    when (@direction.nil? and @comparator.nil?)
      @distance.to_s(distance_options)
    when @comparator.nil?
      [
        @distance.to_s(distance_options),
        @direction.to_s(direction_options),
      ].join(' ')
    when @direction.nil?
      [
        I18n.t('comparison.' + @comparator.to_s),
        @distance.to_s(distance_options),
      ].join(' ')
    else
      [
        I18n.t('comparison.' + @comparator.to_s),
        @distance.to_s(distance_options),
        @direction.to_s(direction_options),
      ].join(' ')
    end
  end
end
