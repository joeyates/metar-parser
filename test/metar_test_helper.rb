require 'rubygems' if RUBY_VERSION < '1.9'
require File.join(File.expand_path(File.dirname(__FILE__) + '/../lib'), 'metar')

Metar::Station.load_local

RAW_EXAMPLE = "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005"
# Use a fixed string for testing
Metar::Raw.instance_eval do
  def fetch(cccc)
    RAW_EXAMPLE
  end
end

require 'test/unit'

