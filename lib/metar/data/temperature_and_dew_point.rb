class Metar::Data::TemperatureAndDewPoint < Metar::Data::Base
  def self.parse(raw)
    if raw =~ /^(M?\d+|XX|\/\/)\/(M?\d+|XX|\/\/)?$/
      temperature = Metar::Data::Temperature.parse($1)
      dew_point = Metar::Data::Temperature.parse($2)
      new(raw, temperature: temperature, dew_point: dew_point)
    end
  end

  attr_reader :temperature
  attr_reader :dew_point
  
  def initialize(raw, temperature:, dew_point:)
    @raw = raw
    @temperature = temperature
    @dew_point = dew_point
  end
end
