require "i18n"
require "m9t"

# Adds a parse method to the M9t base class
class Metar::Data::Temperature < M9t::Temperature
  def self.parse(raw)
    if raw =~ /^(M?)(\d+)$/
      sign = $1
      value = $2.to_i
      value *= -1 if sign == 'M'
      new(value)
    else
      nil
    end
  end

  def to_s(options = {})
    options = {abbreviated: true, precision: 0}.merge(options)
    super(options)
  end
end
