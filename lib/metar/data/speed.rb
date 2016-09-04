require "i18n"
require "m9t"

# Adds a parse method to the M9t base class
class Metar::Data::Speed < M9t::Speed
  METAR_UNITS = {
    ""    => :kilometers_per_hour,
    "KMH" => :kilometers_per_hour,
    "MPS" => :meters_per_second,
    "KT"  => :knots,
  }

  def self.parse(raw)
    case
    when raw =~ /^(\d+)(|KT|MPS|KMH)$/
      # Call the appropriate factory method for the supplied units
      send(METAR_UNITS[$2], $1.to_i)
    else
      nil
    end
  end
end
