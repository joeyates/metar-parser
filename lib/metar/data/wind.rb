class Metar::Data::Wind < Metar::Data::Base
  def self.parse(raw)
    case
    when raw =~ /^(\d{3})(\d{2}(|MPS|KMH|KT))$/
      return nil if $1.to_i > 360
      new(
        raw,
        direction: Metar::Data::Direction.new($1),
        speed: Metar::Data::Speed.parse($2)
      )
    when raw =~ /^(\d{3})(\d{2})G(\d{2,3}(|MPS|KMH|KT))$/
      return nil if $1.to_i > 360
      new(
        raw,
        direction: Metar::Data::Direction.new($1),
        speed: Metar::Data::Speed.parse($2 + $4),
        gusts: Metar::Data::Speed.parse($3)
      )
    when raw =~ /^VRB(\d{2})G(\d{2,3})(|MPS|KMH|KT)$/
      speed = $1 + $3
      gusts = $2 + $3
      new(
        raw,
        direction: :variable_direction,
        speed: Metar::Data::Speed.parse(speed),
        gusts: Metar::Data::Speed.parse(gusts)
      )
    when raw =~ /^VRB(\d{2}(|MPS|KMH|KT))$/
      new(raw, direction: :variable_direction, speed: Metar::Data::Speed.parse($1))
    when raw =~ /^\/{3}(\d{2}(|MPS|KMH|KT))$/
      new(raw, direction: :unknown_direction, speed: Metar::Data::Speed.parse($1))
    when raw =~ %r(^/////(|MPS|KMH|KT)$)
      new(raw, direction: :unknown_direction, speed: :unknown_speed)
    else
      nil
    end
  end

  attr_reader :direction, :speed, :gusts

  def initialize(raw, direction:, speed:, gusts: nil)
    @raw = raw
    @direction, @speed, @gusts = direction, speed, gusts
  end

  def to_s(options = {})
    options = {
      direction_units: :compass,
      speed_units:     :kilometers_per_hour,
    }.merge(options)
    speed =
      case @speed
      when :unknown_speed
           I18n.t('metar.wind.unknown_speed')
      else
        @speed.to_s(
          abbreviated: true,
          precision:   0,
          units:       options[:speed_units]
        )
      end
    direction =
      case @direction
      when :variable_direction
           I18n.t('metar.wind.variable_direction')
      when :unknown_direction
           I18n.t('metar.wind.unknown_direction')
      else
        @direction.to_s(units: options[:direction_units])
      end
    s = "#{speed} #{direction}"
    if not @gusts.nil?
      g = @gusts.to_s(
        abbreviated: true,
        precision:   0,
        units:       options[:speed_units]
      )
      s += " #{I18n.t('metar.wind.gusts')} #{g}"
    end
    s
  end
end
