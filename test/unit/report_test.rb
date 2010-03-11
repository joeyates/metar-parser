#!/usr/bin/env ruby
# encoding: utf-8

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarReport < Test::Unit::TestCase
  
  def setup
    I18n.locale = :en
  end

  def test_wind_knots
    raw = Metar::Raw.new('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    parser = Metar::Parser.new(raw)
    parser.analyze
    report = Metar::Report.new(parser)
    assert_equal('10° 7 knots', report.wind)
    I18n.locale = :it
    assert_equal('10° 7 nodi', report.wind)
  end

end
