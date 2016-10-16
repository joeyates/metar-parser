require "i18n"
require "m9t"

class Metar::Data::VerticalVisibility < Metar::Data::Base
  def self.parse(raw)
    if !raw
      return nil
    end
    m1 = raw.match(/^VV(\d{3})$/)
    if m1
      return new(raw, distance: Metar::Data::Distance.new(m1[1].to_f * 30.48))
    end

    if raw == '///'
      return new(raw, distance: Metar::Data::Distance.new)
    end

    nil
  end

  attr_reader :distance

  def initialize(raw, distance:)
    @raw = raw
    @distance = distance
  end

  def value
    distance.value
  end
end
