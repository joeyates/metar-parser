# * coding: UTF-8 *
require 'rubygems' if RUBY_VERSION < '1.9'
require 'i18n'

module Metar
  class Report

    locales_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'locales'))

    I18n.load_path = Dir.glob("#{ locales_path }/*.yml")
    I18n.locale = :en

    def initialize(report)
      @report = report
    end

    def wind
      '10° 7 knots'
    end

  end
end

__END__


    def attributes_to_s
      attrib = attributes
      texts = {}
      texts[:wind]                 = attrib[:wind]                            if attrib[:wind]
      texts[:variable_wind]        = attrib[:variable_wind]                   if attrib[:variable_wind]
      texts[:visibility]           = "%u meters" % attrib[:visibility].value  if attrib[:visibility]
      texts[:runway_visible_range] = attrib[:runway_visible_range].join(', ') if attrib[:runway_visible_range]
      texts[:present_weather]      = attrib[:present_weather].join(', ')      if attrib[:present_weather]
      texts[:sky_conditions]       = attrib[:sky_conditions].join(', ')       if attrib[:sky_conditions]
      texts[:temperature]          = "%u celcius" % attrib[:temperature]      if attrib[:temperature]
      texts[:dew_point]            = "%u celcius" % attrib[:dew_point]        if attrib[:dew_point]
      texts[:remarks]              = attrib[:remarks].join(', ')              if attrib[:remarks]

      texts
    end

    def to_s
      # If attributes supplied an ordered hash, the hoop-jumping below
      # wouldn't be necessary
      attr = attributes_to_s
      [:station_code, :time, :observer, :wind, :variable_wind, :visibility, :runway_visible_range,
       :present_weather, :sky_conditions, :temperature, :dew_point, :remarks].collect do |key|
        attr[key] ? self.symbol_to_s(key) + ": " + attr[key] : nil
      end.compact.join("\n")
    end

    private

    # :symbol_etc => 'Symbol etc'
    def self.symbol_to_s(sym)
      sym.to_s.gsub(/^([a-z])/) {$1.upcase}.gsub(/_([a-z])/) {" #$1"}
    end
