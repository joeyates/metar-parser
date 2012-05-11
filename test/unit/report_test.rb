#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift( File.expand_path( '..', File.dirname( __FILE__ ) ) )
require 'metar_test_helper'

class TestMetarReport < Test::Unit::TestCase
  def test_name
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_equal('Firenze / Peretola', report.station_name)
  end

  def test_date
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_equal('06/02/2010', report.date)
  end

  def test_time
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_equal('15:20', report.time)
  end

  def test_wind_knots
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_equal('13km/h N', report.wind)
  end

  def test_variable_wind
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    I18n.locale = :en
    assert_equal('350 degrees - 50 degrees', report.variable_wind)
  end

  def test_visibility
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_equal('more than 10km', report.visibility)
  end

  def test_runway_visible_range
    report = setup_report('ESSB', "2010/02/15 10:20\nESSB 151020Z 26003KT 2000 R12/1000N R30/1500N VV002 M07/M07 Q1013 1271//55")
    I18n.locale = :en
    assert_equal('runway 12: 1000m, runway 30: 1500m', report.runway_visible_range)
    I18n.locale = :it
    assert_equal('pista 12: 1000m, pista 30: 1500m', report.runway_visible_range)
  end

  def test_runway_visible_range_variable
    report = setup_report('KPDX', "2010/02/15 11:08\nKPDX 151108Z 11006KT 1/4SM R10R/1600VP6000FT FG OVC002 05/05 A3022 RMK AO2")
    I18n.locale = :en
    assert_equal('runway 10R: from 1600ft to more than 6000ft', report.runway_visible_range)
  end

  def test_present_weather
    report = setup_report('DAAS', "2010/02/15 10:00\nDAAS 151000Z 16012KT 9999 -RA FEW010 BKN026 06/05 Q1006")
    assert_equal('light rain', report.present_weather)
    I18n.locale = :it
    assert_equal('pioggia leggera', report.present_weather)
  end

  def test_sky_conditions
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    I18n.locale = :en
    assert_equal('scattered cloud at 1050m, broken cloud at 2400m', report.sky_conditions)
    I18n.locale = :it
    assert_equal('nuvole sparse a 1050m, nuvolosità parziale a 2400m', report.sky_conditions)
  end

  def test_vertical_visibility
    report = setup_report('CYXS', "2010/02/15 10:34\nCYXS 151034Z AUTO 09003KT 1/8SM FZFG VV001 M03/M03 A3019 RMK SLP263 ICG")
    assert_equal('30m', report.vertical_visibility)
  end

  def test_temperature
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_equal('8°C', report.temperature)
  end

  def test_dew_point
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_equal( '2°C', report.dew_point )
  end

  def test_sea_level_pressure
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_equal('1.00500 bar', report.sea_level_pressure)
  end

  def test_to_s
    report = setup_report('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    Metar::Report.attributes -= [:station_code, :variable_wind, :observer, :remarks]
    I18n.locale = :en
    assert_equal( "name: Firenze / Peretola\ncountry: Italy\ntime: 15:20\nwind: 13km/h N\nvisibility: more than 10km\nsky: broken cloud\ntemperature: 8°C", report.to_s )
  end

  private

  def setup_report(cccc, metar)
    raw = Metar::Raw.new(cccc, metar)
    parser = Metar::Parser.new(raw)
    Metar::Report.new(parser)
  end

end
