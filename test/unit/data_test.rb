#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift( File.expand_path( '..', File.dirname( __FILE__ ) ) )
require 'metar_test_helper'

class TestMetarData < Test::Unit::TestCase
  # VariableWind
  def test_variable_wind
    variable_wind = Metar::VariableWind.parse('350V050')
    assert_equal(350, variable_wind.direction1.value)
    assert_equal(50, variable_wind.direction2.value)
  end

  # Visibility
  def test_visibility_parse_blank
    visibility = Metar::Visibility.parse('')
    assert_nil(visibility)
  end

  def test_visibility_parse_comparator_defaults_to_nil
    visibility = Metar::Visibility.parse('0200NDV')
    assert_nil(visibility.comparator)
  end

  def test_visibility_parse_9999
    visibility = Metar::Visibility.parse('9999')
    assert_equal('more than 10km', visibility.to_s)
    I18n.locale = :it
    assert_equal('piú di 10km', visibility.to_s)
  end

  def test_visibility_parse_ndv
    visibility = Metar::Visibility.parse('0200NDV')
    assert_equal(200, visibility.distance.value)
    assert_nil(visibility.direction)
  end

  def test_visibility_parse_us_fractions_1_4
    visibility = Metar::Visibility.parse('1/4SM')
    assert_equal(M9t::Distance.miles(0.25).value, visibility.distance.value)
  end

  def test_visibility_parse_us_fractions_2_1_2
    visibility = Metar::Visibility.parse('2 1/2SM')
    assert_equal(M9t::Distance.miles(2.5).value, visibility.distance.value)
  end

  def test_visibility_parse_kilometers
    visibility = Metar::Visibility.parse('5KM')
    assert_equal(5000.0, visibility.distance.value)
  end

  def test_visibility_parse_compass
    visibility = Metar::Visibility.parse('5NE')
    assert_equal(5000.0, visibility.distance.value)
    assert_equal(45.0, visibility.direction.value)
    assert_equal( '5km NE', visibility.to_s )
  end

  # RunwayVisibleRange
  def test_runway_visible_range
    runway_visible_range = Metar::RunwayVisibleRange.parse('R12/1000N')
    assert_equal('12', runway_visible_range.designator)
    assert_equal(1000, runway_visible_range.visibility1.distance.value)
    assert_equal(:no_change, runway_visible_range.tendency)
    assert_equal('runway 12: 1000m', runway_visible_range.to_s)
  end

  def test_runway_visible_range_descriptor_with_letter
    runway_visible_range = Metar::RunwayVisibleRange.parse('R12R/1000N')
    assert_equal('12R', runway_visible_range.designator)
  end

  def test_runway_visible_range_variable
    runway_visible_range = Metar::RunwayVisibleRange.parse('R10R/1600VP6000FT')
    assert_equal('10R', runway_visible_range.designator)
    assert_equal(1600, runway_visible_range.visibility1.distance.to_feet)
    assert_equal(6000, runway_visible_range.visibility2.distance.to_feet)
  end

  # WeatherPhenomenon
  def test_weather_phenomenon_snra
    phenomenon = Metar::WeatherPhenomenon.parse('SNRA')
    assert_equal('snow and rain', phenomenon.to_s)
    I18n.locale =  :it
    assert_equal('neve mista a pioggia', phenomenon.to_s)
  end

  def test_weather_phenomenon_fzfg
    freezing_rain = Metar::WeatherPhenomenon.parse('FZFG')
    assert_equal('freezing fog', freezing_rain.to_s)
    I18n.locale =  :it
    assert_equal('nebbia ghiacciata', freezing_rain.to_s)
  end

  def test_weather_phenomenon_with_modifier_plus
    phenomenon = Metar::WeatherPhenomenon.parse('+RA')
    assert_equal('heavy', phenomenon.modifier)
    assert_equal('heavy rain', phenomenon.to_s)
    I18n.locale =  :it
    assert_equal('pioggia intensa', phenomenon.to_s)
  end

  def test_weather_phenomenon_with_modifier_minus
    phenomenon = Metar::WeatherPhenomenon.parse('-RA')
    assert_equal('light', phenomenon.modifier)
    assert_equal('light rain', phenomenon.to_s)
    I18n.locale =  :it
    assert_equal('pioggia leggera', phenomenon.to_s)
  end

  # SkyCondition
  def test_sky_condition_nsc
    sky_condition = Metar::SkyCondition.parse('NSC')
    assert_nil(sky_condition.quantity)
    assert_nil(sky_condition.height)
    assert_equal('clear skies', sky_condition.to_s)
    I18n.locale =  :it
    assert_equal('cielo sereno', sky_condition.to_s)
  end

  def test_sky_condition_clr
    sky_condition = Metar::SkyCondition.parse('CLR')
    assert_equal('clear skies', sky_condition.to_s)
    I18n.locale =  :it
    assert_equal('cielo sereno', sky_condition.to_s)
  end

  def test_sky_condition_broken
    sky_condition = Metar::SkyCondition.parse('BKN016')
    assert_equal('broken', sky_condition.quantity)
    assert_equal(480, sky_condition.height.value)
    assert_equal('broken cloud at 480m', sky_condition.to_s)
    I18n.locale =  :it
    assert_equal('nuvolosità parziale a 480m', sky_condition.to_s)
  end

  def test_sky_condition_few
    sky_condition = Metar::SkyCondition.parse('FEW016')
    assert_equal('few', sky_condition.quantity)
    assert_equal(480, sky_condition.height.value)
    assert_equal('few clouds at 480m', sky_condition.to_s)
    I18n.locale =  :it
    assert_equal('poche nuvole a 480m', sky_condition.to_s)
  end

  def test_sky_condition_ovc
    sky_condition = Metar::SkyCondition.parse('OVC016')
    assert_equal('overcast', sky_condition.quantity)
    assert_equal(480, sky_condition.height.value)
    assert_equal('overcast at 480m', sky_condition.to_s)
    I18n.locale =  :it
    assert_equal('chiuso a 480m', sky_condition.to_s)
  end

  def test_sky_condition_sct
    sky_condition = Metar::SkyCondition.parse( 'SCT016' )
    assert_equal('scattered', sky_condition.quantity)
    assert_equal(480, sky_condition.height.value)
    assert_equal('scattered cloud at 480m', sky_condition.to_s)
    I18n.locale =  :it
    assert_equal('nuvole sparse a 480m', sky_condition.to_s)
  end

  def test_sky_condition_cloud_types_cb
    sky_condition = Metar::SkyCondition.parse('SCT016CB')
    assert_equal('scattered', sky_condition.quantity)
    assert_equal('cumulonimbus', sky_condition.type)
    assert_equal(480, sky_condition.height.value)
    assert_equal('scattered cumulonimbus at 480m', sky_condition.to_s)
    I18n.locale =  :it
    assert_equal('cumulonembi sparsi a 480m', sky_condition.to_s)
  end

  def test_sky_condition_cloud_types_tcu
    sky_condition = Metar::SkyCondition.parse('SCT016TCU')
    assert_equal('scattered', sky_condition.quantity)
    assert_equal('towering cumulus', sky_condition.type)
    assert_equal(480, sky_condition.height.value)
    assert_equal('scattered towering cumulus clouds at 480m', sky_condition.to_s)
    I18n.locale =  :it
    assert_equal('cumulonembi sparsi a 480m', sky_condition.to_s)
  end

  # VerticalVisibility
  def test_vertical_visibility
    vertical_visibility = Metar::VerticalVisibility.parse('VV001')
    assert_equal(30, vertical_visibility.value)
    assert_equal('30m', vertical_visibility.to_s)
  end

  def test_vertical_visibility_unknown
    vertical_visibility = Metar::VerticalVisibility.parse('///')
    assert_nil(vertical_visibility.value)
    assert_equal('unknown', vertical_visibility.to_s)
    I18n.locale =  :it
    assert_equal('sconosciuto', vertical_visibility.to_s)
  end

end

