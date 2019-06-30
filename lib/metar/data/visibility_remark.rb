# frozen_string_literal: true

module Metar
  module Data
    class VisibilityRemark < Metar::Data::Visibility
      def self.parse(raw)
        metres, direction = raw.scan(/^(\d{4})([NESW]?)$/)[0]
        distance = Metar::Data::Distance.new(metres)

        new(
          raw,
          distance: distance,
          direction: direction,
          comparator: :more_than
        )
      end
    end
  end
end
