class Metar::Data::Visibility < Metar::Data::Base
  def self.parse(raw)
    case
    when raw == '9999'
      new(raw, distance: Metar::Distance.new(10000), comparator: :more_than)
    when raw =~ /(\d{4})NDV/ # WMO
      new(raw, distance: Metar::Distance.new($1.to_f)) # Assuming meters
    when (raw =~ /^((1|2)\s|)([1357])\/([248]|16)SM$/) # US
      miles          = $1.to_f + $3.to_f / $4.to_f
      distance       = Metar::Distance.miles(miles)
      distance.units = :miles
        new(raw, distance: distance)
    when raw =~ /^(\d+)SM$/ # US
      distance       = Metar::Distance.miles($1.to_f)
      distance.units = :miles
        new(raw, distance: distance)
    when raw == 'M1/4SM' # US
      distance       = Metar::Distance.miles(0.25)
      distance.units = :miles
        new(raw, distance: distance, comparator: :less_than)
    when raw =~ /^(\d+)KM$/
      new(raw, distance: Metar::Distance.kilometers($1))
    when raw =~ /^(\d+)$/ # We assume meters
      new(raw, distance: Metar::Distance.new($1))
    when raw =~ /^(\d+)(N|NE|E|SE|S|SW|W|NW)$/
      new(
        raw,
        distance: Metar::Distance.meters($1),
        direction: M9t::Direction.compass($2)
      )
    else
      nil
    end
  end

  attr_reader :distance, :direction, :comparator

  def initialize(raw, distance:, direction: nil, comparator: nil)
    @raw = raw
    @distance, @direction, @comparator = distance, direction, comparator
  end

  def to_s(options = {})
    distance_options = {
      abbreviated: true,
      precision:   0,
      units:       :kilometers,
    }.merge(options)
    direction_options = {units: :compass}
    case
    when (@direction.nil? and @comparator.nil?)
      @distance.to_s(distance_options)
    when @comparator.nil?
      [
        @distance.to_s(distance_options),
        @direction.to_s(direction_options),
      ].join(' ')
    when @direction.nil?
      [
        I18n.t('comparison.' + @comparator.to_s),
        @distance.to_s(distance_options),
      ].join(' ')
    else
      [
        I18n.t('comparison.' + @comparator.to_s),
        @distance.to_s(distance_options),
        @direction.to_s(direction_options),
      ].join(' ')
    end
  end
end
