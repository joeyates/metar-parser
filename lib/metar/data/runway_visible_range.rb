class Metar::Data::RunwayVisibleRange < Metar::Data::Base
  TENDENCY   = {'' => nil, 'N' => :no_change, 'U' => :improving, 'D' => :worsening}
  COMPARATOR = {'' => nil, 'P' => :more_than, 'M' => :less_than}
  UNITS      = {'' => :meters, 'FT' => :feet}

  def self.parse(raw)
    case
    when raw =~ /^R(\d+[RLC]?)\/(P|M|)(\d{4})(FT|)\/?(N|U|D|)$/
      designator = $1
      comparator = COMPARATOR[$2]
      count      = $3.to_f
      units      = UNITS[$4]
      tendency   = TENDENCY[$5]
      distance   = Metar::Data::Distance.send(units, count)
      visibility = Metar::Data::Visibility.new(
        nil, distance: distance, comparator: comparator
      )
      new(
        raw,
        designator: designator, visibility1: visibility, tendency: tendency
      )
    when raw =~ /^R(\d+[RLC]?)\/(P|M|)(\d{4})V(P|M|)(\d{4})(FT|)\/?(N|U|D)?$/
      designator  = $1
      comparator1 = COMPARATOR[$2]
      count1      = $3.to_f
      comparator2 = COMPARATOR[$4]
      count2      = $5.to_f
      units       = UNITS[$6]
      tendency    = TENDENCY[$7]
      distance1   = Metar::Data::Distance.send(units, count1)
      distance2   = Metar::Data::Distance.send(units, count2)
      visibility1 = Metar::Data::Visibility.new(
        nil, distance: distance1, comparator: comparator1
      )
      visibility2 = Metar::Data::Visibility.new(
        nil, distance: distance2, comparator: comparator2
      )
      new(
        raw,
        designator: designator,
        visibility1: visibility1, visibility2: visibility2,
        tendency: tendency, units: units
      )
    else
      nil
    end
  end

  attr_reader :designator, :visibility1, :visibility2, :tendency

  def initialize(
    raw,
    designator:, visibility1:, visibility2: nil, tendency: nil, units: :meters
  )
    @raw = raw
    @designator, @visibility1, @visibility2, @tendency, @units = designator, visibility1, visibility2, tendency, units
  end

  def to_s
    distance_options = {
      abbreviated: true,
      precision:   0,
      units:       @units,
    }
    s =
      if @visibility2.nil?
        I18n.t('metar.runway_visible_range.runway') +
          ' '  + @designator +
          ': ' + @visibility1.to_s(distance_options)
      else
        I18n.t('metar.runway_visible_range.runway') +
          ' '  + @designator +
          ': ' + I18n.t('metar.runway_visible_range.from') +
          ' '  + @visibility1.to_s(distance_options) +
          ' '  + I18n.t('metar.runway_visible_range.to') +
          ' '  + @visibility2.to_s(distance_options)
      end

    if ! tendency.nil?
      s += ' ' + I18n.t("tendency.#{tendency}")
    end

    s
  end
end
