require 'rubygems' if RUBY_VERSION < '1.9'

module Metar

  class Parser

    def initialize(raw_report)
      @raw_report = raw_report
    end

  end

end
