# frozen_string_literal: true

require "i18n"
require "m9t"

class Metar::Data::Direction < M9t::Direction
  def initialize(direction)
    direction = M9t::Direction.normalize(direction.to_f)
    super(direction)
  end
end
