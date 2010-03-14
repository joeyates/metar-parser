#!/usr/bin/env ruby

$:.unshift('/home/joe/code/ruby/m9t/lib') ##### DO NOT COMMIT
require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarParser < Test::Unit::TestCase

  def setup
  end

  def test_new
    raw = Metar::Raw.new('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    assert_nothing_thrown do
      report = Metar::Parser.new(raw)
    end
  end

  def test_date
    parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    assert_equal(Date.new(2010, 2, 6), parser.date)
  end

  def test_wind
    parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    assert_in_delta(240, parser.wind.direction.value, 0.0001)
    assert_in_delta(6, parser.wind.speed.to_knots, 0.0001)
  end

  def test_variable_wind
    parser = setup_parser('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
    assert_in_delta(350, parser.variable_wind.direction1.value, 0.0001)
    assert_in_delta(50, parser.variable_wind.direction2.value, 0.0001)
  end

  def test_visibility_miles_and_fractions
    parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    assert_in_delta(1.75, parser.visibility.distance.to_miles, 0.01)
    assert_equal(:miles, parser.visibility.distance.options[:units])
  end

  def test_runway_visible_range
    parser = setup_parser('ESSB', "2010/02/15 10:20\nESSB 151020Z 26003KT 2000 R12/1000N R30/1500N VV002 M07/M07 Q1013 1271//55")
    assert_equal(2, parser.runway_visible_range.length)
    assert_equal(12, parser.runway_visible_range[0].number)
    assert_equal(1000, parser.runway_visible_range[0].visibility1.distance.value)
    assert_equal(:no_change, parser.runway_visible_range[0].tendency)
  end

  def test_present_weather
    parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    assert_equal(1, parser.present_weather.length)
    assert_equal('light', parser.present_weather[0].modifier)
    assert_equal('snow', parser.present_weather[0].phenomenon)
  end

  def test_sky_conditions
    parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    assert_equal(2, parser.sky_conditions.length)
    assert_equal('broken', parser.sky_conditions[0].quantity)
    assert_equal(480, parser.sky_conditions[0].height.value)
    assert_equal('overcast', parser.sky_conditions[1].quantity)
    assert_equal(900, parser.sky_conditions[1].height.value)
  end

  def test_vertical_visibility
    parser = setup_parser('CYXS', "2010/02/15 10:34\nCYXS 151034Z AUTO 09003KT 1/8SM FZFG VV001 M03/M03 A3019 RMK SLP263 ICG")
    assert_equal(30, parser.vertical_visibility.value)
  end

  def test_temperature
    parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    assert_equal(-17, parser.temperature.value)
  end

  def test_dew_point
    parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    assert_equal(-20, parser.dew_point.value)
  end

  def test_sea_level_pressure
    parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
    assert_equal(29.10, parser.sea_level_pressure.to_inches_of_mercury)
    assert_equal(:bar, parser.sea_level_pressure.options[:units])
  end

  private

  def setup_parser(cccc, metar)
    raw = Metar::Raw.new(cccc, metar)
    Metar::Parser.new(raw)
  end

end
