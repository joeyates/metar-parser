#!/usr/bin/env ruby
# encoding: utf-8

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarData < Test::Unit::TestCase
  
  def setup
    I18n.locale = :en
  end

  def test_m9t_translations_available
    assert_equal('10 kilometers', M9t::Distance.new(10000, {:units => :kilometers, :precision => 0}).to_s)
  end

  # Speed
  def test_speed_parse_blank_gives_nil
    speed = Metar::Speed.parse('')
    assert_nil(speed)
  end

  def test_class_options_set
    assert_not_nil(Metar::Speed.options)
  end

  def test_speed_parse_default_unit
    speed = Metar::Speed.parse('12')
    assert_equal(12, speed.to_kilometers_per_hour)
    assert_equal(:kilometers_per_hour, speed.options[:units])
  end

  def test_speed_parse_kilometers_per_hour
    speed = Metar::Speed.parse('12KMH')
    assert_equal(12, speed.to_kilometers_per_hour)
    assert_equal(:kilometers_per_hour, speed.options[:units])
  end

  def test_speed_parse_knots
    speed = Metar::Speed.parse('12KT')
    assert_equal(:knots, speed.options[:units])
  end

  def test_speed_parse_meters_per_second
    speed = Metar::Speed.parse('12MPS')
    assert_equal(:meters_per_second, speed.options[:units])
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

  # Distance
  def test_distance_nil
    distance = Metar::Distance.new
    I18n.locale = :en
    assert_equal('unknown', distance.to_s)
    I18n.locale = :it
    assert_equal('sconosciuto', distance.to_s)
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
    assert_equal(:miles, visibility.distance.options[:units])
  end

  def test_visibility_parse_us_fractions_2_1_2
    visibility = Metar::Visibility.parse('2 1/2SM')
    assert_equal(M9t::Distance.miles(2.5).value, visibility.distance.value)
    assert_equal(:miles, visibility.distance.options[:units])
  end

  def test_visibility_parse_kilometers
    visibility = Metar::Visibility.parse('5KM')
    assert_equal(5000.0, visibility.distance.value)
    assert_equal(:kilometers, visibility.distance.options[:units])
  end

  def test_visibility_parse_compass
    visibility = Metar::Visibility.parse('5NE')
    assert_equal(5000.0, visibility.distance.value)
    assert_equal(:kilometers, visibility.distance.options[:units])
    assert_equal(45.0, visibility.direction.value)
    visibility.distance.options[:units] = :kilometers
    visibility.distance.options[:abbreviated] = true
    visibility.distance.options[:precision] = 0
    visibility.direction.options[:units] = :compass
    assert_equal('5km NE', visibility.to_s)
  end
  
  # RunwayVisibleRange
  def test_runway_visible_range
  end

  # Wind
  def test_wind
  end

  # VariableWind
  def test_variable_wind
  end

  # WeatherPhenomenon
  def test_weather_phenomenon_i18n
    freezing_rain = Metar::WeatherPhenomenon.parse('FZFG')
    assert_equal('freezing fog', freezing_rain.to_s)
    I18n.locale =  :it
    assert_equal('nebbia ghiacciata', freezing_rain.to_s)
  end

  # SkyCondition
  def test_sky_condition
  end

  # VerticalVisibility
  def test_vertical_visibility
  end

  # Pressure
  def test_bar
    assert_equal(1.0, Metar::Pressure.new(1.0).value)
  end

  def test_hectopascals
    assert_equal(0.001, Metar::Pressure.hectopascals(1.0).value)
  end

  def test_inches_of_mercury
    assert_in_delta(0.03386, Metar::Pressure.inches_of_mercury(1.0).value, 0.00001)
  end

end
