class Metar::Data::Pressure < Metar::Data::Base
  def self.parse(raw)
    case
    when raw =~ /^Q(\d{4})$/
      new(raw, pressure: M9t::Pressure.hectopascals($1.to_f))
    when raw =~ /^A(\d{4})$/
      new(raw, pressure: M9t::Pressure.inches_of_mercury($1.to_f / 100.0))
    else
      nil
    end
  end

  attr_reader :pressure

  def initialize(raw, pressure:)
    @raw = raw
    @pressure = pressure
  end

  def value
    pressure.value
  end
end
