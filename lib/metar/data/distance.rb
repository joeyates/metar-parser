require "i18n"
require "m9t"

class Metar::Data::Distance < M9t::Distance
  attr_accessor :units

  # nil is taken to mean 'data unavailable'
  def initialize(meters = nil)
    @units = :meters
    if meters
      super
    else
      @value = nil
    end
  end

  # Handles nil case differently to M9t::Distance
  def to_s(options = {})
    options = {
      units:       units,
      precision:   0,
      abbreviated: true,
    }.merge(options)
    return I18n.t("metar.distance.unknown") if @value.nil?
    super(options)
  end
end
