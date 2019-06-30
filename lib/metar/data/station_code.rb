# frozen_string_literal: true

module Metar
  module Data
    class StationCode < Metar::Data::Base
      def self.parse(raw)
        new(raw) if raw =~ /^[A-Z][A-Z0-9]{3}$/
      end
    end
  end
end
