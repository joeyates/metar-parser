#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarParser < Test::Unit::TestCase
  
  def setup
  end

  def test_new
    raw = Metar::Raw.new('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_nothing_thrown do
      report = Metar::Parser.new(raw)
    end
  end

  def test_miles_and_fractions
    raw = Metar::Raw.new('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    report = Metar::Parser.new(raw)
    assert_in_delta(1.75, report.visibility.distance.to_miles, 0.01)
    assert_equal(:miles, report.visibility.distance.options[:units])
  end

end
