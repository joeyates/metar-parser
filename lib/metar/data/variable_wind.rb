class Metar::Data::VariableWind < Metar::Data::Base
  def self.parse(raw)
    if raw =~ /^(\d+)V(\d+)$/
      new(
        raw,
        direction1: Metar::Data::Direction.new($1),
        direction2: Metar::Data::Direction.new($2)
      )
    else
      nil
    end
  end

  attr_reader :direction1
  attr_reader :direction2

  def initialize(raw, direction1:, direction2:)
    @raw = raw
    @direction1, @direction2 = direction1, direction2
  end

  def to_s
    "#{direction1.to_s(units: :compass)} - #{direction2.to_s(units: :compass)}"
  end
end
