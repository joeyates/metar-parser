#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift( File.expand_path( '..', File.dirname( __FILE__ ) ) )
require 'metar_test_helper'

class TestMetarData < Test::Unit::TestCase
  
  def setup
    I18n.locale = :en
  end

  def test_m9t_translations_available
    distance = M9t::Distance.new( 10000 )

    assert_equal( '10 kilometers', distance.to_s( :units     => :kilometers,
                                                  :precision => 0 ) )
  end

  # Distance
  def test_distance_nil
    distance = Metar::Distance.new
    I18n.locale = :en
    assert_equal('unknown', distance.to_s)
    I18n.locale = :it
    assert_equal('sconosciuto', distance.to_s)
  end

  def test_distance_with_default_options
    distance = Metar::Distance.new(123)
    assert_equal(123, distance.value)
  end

  def test_distance_setting_options
    distance = Metar::Distance.new( 123 )

    assert_equal('404ft', distance.to_s( :units => :feet ) )
  end

  # Speed
  def test_speed_parse_blank_gives_nil
    speed = Metar::Speed.parse('')
    assert_nil(speed)
  end

  def test_speed_class_options_set
    assert_not_nil(Metar::Speed.options)
  end

  def test_speed_parse_without_units
    speed = Metar::Speed.parse('12')
    assert_equal(12, speed.to_kilometers_per_hour)
  end

  def test_speed_parse_kilometers_per_hour
    speed = Metar::Speed.parse('12KMH')
    assert_equal(12, speed.to_kilometers_per_hour)
  end

  def test_speed_parse_knots
    speed = Metar::Speed.parse('12KT')

    assert_equal(12.0, speed.to_knots)
  end

  def test_speed_parse_kilometers_per_hour_is_default
    speed = Metar::Speed.parse( '12' )
    assert_in_delta( M9t::Speed.kilometers_per_hour( 12 ).to_f, speed.to_f, 0.000001 )
  end

  def test_speed_parse_explicit_units
    speed = Metar::Speed.parse( '12MPS' )
    assert_in_delta( 12, speed.to_f, 0.000001 )

    speed = Metar::Speed.parse( '12KMH' )
    assert_in_delta( M9t::Speed.kilometers_per_hour( 12 ).to_f, speed.to_f, 0.000001 )

    speed = Metar::Speed.parse( '12KT' )
    assert_in_delta( M9t::Speed.knots( 12 ).to_f, speed.to_f, 0.000001 )
  end

  # Temperature
  def test_temperature_parse_blank_gives_nil
    temperature = Metar::Temperature.parse('')
    assert_nil(temperature)
  end

  def test_temperature_parse_incorrect_gives_nil
    temperature = Metar::Temperature.parse('XYZ')
    assert_nil(temperature)
  end

  def test_temperature_parse_positive
    temperature = Metar::Temperature.parse('12')
    assert_equal(12, temperature.value)
  end

  def test_temperature_parse_negative
    temperature = Metar::Temperature.parse('M12')
    assert_equal(-12, temperature.value)
  end

  # Pressure
  def test_pressure_parse_hectopascals
    pressure = Metar::Pressure.parse('Q1002')
    assert_equal(1.002, pressure.value)
  end

  def test_pressure_parse_hectopascals_leading_zero
    pressure = Metar::Pressure.parse('Q0992')
    assert_equal(0.992, pressure.value)
  end

  def test_pressure_parse_inches_of_mercury
    pressure = Metar::Pressure.parse('A3019')
    assert_in_delta(1.02235, pressure.value, 0.00001)
  end

  # Wind
  def test_wind_parse_without_units
    wind = Metar::Wind.parse( '18012' )

    assert_equal(180, wind.direction.value)
    assert_equal(12.0, wind.speed.to_kilometers_per_hour)
  end

  def test_wind_parse_mps
    wind = Metar::Wind.parse('18012MPS')
    assert_equal(180, wind.direction.value)
    assert_equal(12.0, wind.speed.value)
  end

  def test_wind_parse_kmh
    wind = Metar::Wind.parse('27012KMH')
    assert_equal(270, wind.direction.value)
    assert_equal(12.0, wind.speed.to_kilometers_per_hour)
  end

  def test_wind_parse_knots
    wind = Metar::Wind.parse('24006KT')

    assert_equal( 240, wind.direction.value )
    assert_equal( 6, wind.speed.to_knots )
    assert_equal( :kilometers_per_hour, wind.options[ :speed_units ] )
  end

  def test_wind_parse_variable_direction
    wind = Metar::Wind.parse( 'VRB20KT' )

    assert_equal( :variable_direction, wind.direction )
    assert_equal( 20, wind.speed.to_knots )
    assert_equal( '37km/h variable direction', wind.to_s )
  end

  def test_wind_parse_unknown_direction
    wind = Metar::Wind.parse('///20KT')
    assert_equal(:unknown_direction, wind.direction)
    assert_equal(20, wind.speed.to_knots)
    assert_equal('37km/h unknown direction', wind.to_s)
  end

  def test_wind_parse_unknown_direction_and_speed
    wind = Metar::Wind.parse('/////')
    assert_equal(:unknown_direction, wind.direction)
    assert_equal(:unknown, wind.speed)
    assert_equal('unknown speed unknown direction', wind.to_s)
  end

  def test_wind_parse_default_output_units_kilometers_per_hour
    wind = Metar::Wind.parse('18012')
    assert_equal(:kilometers_per_hour, wind.options[:speed_units])
    wind = Metar::Wind.parse('18012MPS')
    assert_equal(:kilometers_per_hour, wind.options[:speed_units])
    wind = Metar::Wind.parse('27012KMH')
    assert_equal(:kilometers_per_hour, wind.options[:speed_units])
    wind = Metar::Wind.parse('24006KT')
    assert_equal(:kilometers_per_hour, wind.options[:speed_units])
    wind = Metar::Wind.parse('VRB20KT')
    assert_equal(:kilometers_per_hour, wind.options[:speed_units])
    wind = Metar::Wind.parse('///20KT')
    assert_equal(:kilometers_per_hour, wind.options[:speed_units])
  end

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

