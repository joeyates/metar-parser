#!/usr/bin/env ruby
# encoding: utf-8

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarData < Test::Unit::TestCase
  
  def setup
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
    assert(temperature.value == 12)
  end

  def test_temperature_parse_negative
    temperature = Metar::Temperature.parse('M12')
    assert(temperature.value == -12)
  end

  # Direction
  def test_direction_handles_leading_zero
    direction = Metar::Direction.new('010')
    assert(direction.to_s == '10°')
  end

  # Speed
  def test_speed_parse_blank_gives_nil
    speed = Metar::Speed.parse('')
    assert_nil(speed)
  end

  def test_speed_parse_default_unit
    speed = Metar::Speed.parse('12')
    assert(speed.value == 12)
    assert(speed.unit == :kilometers_per_hour)
  end

  def test_speed_parse_kilometers_per_hour
    speed = Metar::Speed.parse('12KMH')
    assert(speed.value == 12)
    assert(speed.unit == :kilometers_per_hour)
  end

  def test_speed_parse_knots
    speed = Metar::Speed.parse('12KT')
    assert(speed.unit == :knots)
  end

  def test_speed_parse_meters_per_second
    speed = Metar::Speed.parse('12MPS')
    assert(speed.unit == :meters_per_second)
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
    assert(visibility.to_s == 'more than 10 kilometers')
  end

  def test_visibility_parse_ndv
    visibility = Metar::Visibility.parse('0200NDV')
    assert(visibility.distance.value == 200)
    assert_nil(visibility.direction)
  end

  def test_visibility_parse_us_fractions_1_4
    visibility = Metar::Visibility.parse('1/4SM')
    assert(visibility.distance.value == 0.25)
    assert(visibility.distance.unit == :miles)
  end

  def test_visibility_parse_us_fractions_2_1_2
    visibility = Metar::Visibility.parse('2 1/2SM')
    assert(visibility.distance.value == 2.5)
    assert(visibility.distance.unit == :miles)
  end

  def test_visibility_parse_kilometers
    visibility = Metar::Visibility.parse('5KM')
    assert(visibility.distance.value == 5.0)
    assert(visibility.distance.unit == :kilometers)
  end

  def test_visibility_parse_compass
    visibility = Metar::Visibility.parse('5NE')
    assert(visibility.distance.value == 5.0)
    assert(visibility.distance.unit == :kilometers)
    assert(visibility.direction.value == 45)
    Metar::Distance.output.unit = :metric
    Metar::Distance.output.style = :abbreviated
    Metar::Direction.output.unit = :compass
    assert(visibility.to_s == '5km NE')
  end
end
