# frozen_string_literal: true

class Metar::Data::StationCode < Metar::Data::Base
  def self.parse(raw)
    new(raw) if raw =~ /^[A-Z][A-Z0-9]{3}$/
  end
end
