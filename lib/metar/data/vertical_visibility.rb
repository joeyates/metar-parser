require "i18n"
require "m9t"

class Metar::Data::VerticalVisibility < Metar::Data::Base
  def self.parse(raw)
    case
    when raw =~ /^VV(\d{3})$/
      new(raw, distance: Metar::Data::Distance.new($1.to_f * 30.48))
    when raw == '///'
      new(raw, distance: Metar::Data::Distance.new)
    else
      nil
    end
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
