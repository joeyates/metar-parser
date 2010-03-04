#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarReport < Test::Unit::TestCase
  
  def setup
  end

  def test_new
    raw = Metar::Raw.new('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_nothing_thrown do
      report = Metar::Report.new(raw)
    end
  end

  def test_analyze
    raw = Metar::Raw.new('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    report = Metar::Report.new(raw)
    assert_nothing_thrown do
      report.analyze
    end
  end

  def test_miles_and_fractions
    raw = Metar::Raw.new('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    report = Metar::Report.new(raw)
    report.analyze
    assert(report.visibility.distance.value == 1.75)
    assert(report.visibility.distance.unit == :miles)
  end
end
