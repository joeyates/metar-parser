# frozen_string_literal: true

require "i18n"
require "m9t"

module Metar
  module Data
    class Direction < M9t::Direction
      def initialize(direction)
        direction = M9t::Direction.normalize(direction.to_f)
        super(direction)
      end
    end
  end
end
