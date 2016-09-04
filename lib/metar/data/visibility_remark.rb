class Metar::Data::VisibilityRemark < Metar::Data::Visibility
  def self.parse(raw)
    metres, direction = raw.scan(/^(\d{4})([NESW]?)$/)[0]
    distance = Metar::Distance.new(metres)

    new(raw, distance: distance, direction: direction, comparator: :more_than)
  end
end
