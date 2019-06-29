# frozen_string_literal: true

class Metar::Data::StationCode < Metar::Data::Base
  def self.parse(raw)
    if raw =~ /^[A-Z][A-Z0-9]{3}$/
      new(raw)
    end
  end
end
