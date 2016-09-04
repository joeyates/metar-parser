class Metar::Data::Lightning < Metar::Data::Base
  TYPE = {'' => :default}

  def self.parse_chunks(chunks)
    raw = chunks.shift
    m = raw.match(/^LTG(|CG|IC|CC|CA)$/)
    raise 'first chunk is not lightning' if m.nil?
    type = TYPE[m[1]]

    frequency = nil
    distance = nil
    directions = []

    if chunks[0] == 'DSNT'
      distance = Metar::Data::Distance.miles(10) # Should be >10SM, not 10SM
      raw += " " + chunks.shift
    end

    loop do
      if is_compass?(chunks[0])
        direction = chunks.shift
        raw += " " + direction
        directions << direction
      elsif chunks[0] == 'ALQDS'
        directions += ['N', 'E', 'S', 'W']
        raw += " " + chunks.shift
      elsif chunks[0] =~ /^([NESW]{1,2})-([NESW]{1,2})$/
        if is_compass?($1) and is_compass?($2)
          directions += [$1, $2]
          raw += " " + chunks.shift
        else
          break
        end
      elsif chunks[0] == 'AND'
        raw += " " + chunks.shift
      else
        break
      end
    end

    new(
      raw,
      frequency: frequency, type: type,
      distance: distance, directions: directions
    )
  end

  def self.is_compass?(s)
    s =~ /^([NESW]|NE|SE|SW|NW)$/
  end

  attr_accessor :frequency
  attr_accessor :type
  attr_accessor :distance
  attr_accessor :directions

  def initialize(raw, frequency:, type:, distance:, directions:)
    @raw = raw
    @frequency, @type, @distance, @directions = frequency, type, distance, directions
  end
end
