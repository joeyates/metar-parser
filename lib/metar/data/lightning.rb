# frozen_string_literal: true

class Metar::Data::Lightning < Metar::Data::Base
  TYPE = {'' => :default}.freeze

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
      break if chunks[0].nil?

      if is_compass?(chunks[0])
        direction = chunks.shift
        raw += " " + direction
        directions << direction
        next
      end

      if chunks[0] == 'ALQDS'
        directions += %w(N E S W)
        raw += " " + chunks.shift
        next
      end

      m = chunks[0].match(/^([NESW]{1,2})-([NESW]{1,2})$/)
      if m
        break if !is_compass?(m[1])
        break if !is_compass?(m[2])

        directions += [m[1], m[2]]
        raw += " " + chunks.shift
        next
      end

      if chunks[0] == 'AND'
        raw += " " + chunks.shift
        next
      end

      break
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
    @frequency = frequency
    @type = type
    @distance = distance
    @directions = directions
  end
end
