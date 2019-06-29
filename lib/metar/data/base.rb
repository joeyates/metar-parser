# frozen_string_literal: true

class Metar::Data::Base
  def self.parse(raw)
    new(raw)
  end

  attr_reader :raw

  def initialize(raw)
    @raw = raw
  end

  def value
    raw
  end
end
