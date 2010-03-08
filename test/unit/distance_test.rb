#!/usr/bin/env ruby
# encoding: utf-8

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarDistance < Test::Unit::TestCase
  
  def setup
  end

  def teardown
    I18n.locale = :en
  end

  # Basic use
  def test_distance_singular
    distance = Metar::Distance.new(1, :decimals => 0)
    I18n.locale = :en
    assert(distance.to_s == '1 meter')
  end

  def test_distance_plural
    distance = Metar::Distance.new(10, :decimals => 0)
    I18n.locale = :en
    assert(distance.to_s == '10 meters')
    I18n.locale = :it
    assert(distance.to_s == '10 metri')
  end

  def test_distance_default_options_set
    assert_not_nil(Metar::Distance.options)
  end

  def test_distance_default_option_abbreviated
    assert(! Metar::Distance.options[:abbreviated])
  end

  def test_distance_default_option_units
    assert(Metar::Distance.options[:units] == :meters)
  end

  def test_distance_default_option_decimals
    assert(Metar::Distance.options[:decimals] == 3)
  end

  def test_distance_default_options_merged
    distance = Metar::Distance.new(10, {:abbreviated => true})
    assert(distance.options[:units] == :meters)
    assert(distance.options[:decimals] == 3)
  end

  def test_distance_set_default_options_get_inherited
    Metar::Distance.options[:decimals] = 0
    distance = Metar::Distance.new(10)
    assert(distance.options[:decimals] == 0)
  end

  def test_distance_plural_abbreviated
    distance = Metar::Distance.new(10, {:abbreviated => true, :decimals => 0})
    I18n.locale = :en
    assert(distance.to_s == '10m')
    I18n.locale = :it
    assert(distance.to_s == '10m')
  end

  def test_distance_miles_singular
    distance = Metar::Distance.new(Metar::Distance.miles(1), {:units => :miles, :decimals => 0})
    I18n.locale = :en
    assert(distance.to_s == '1 mile')
    I18n.locale = :it
    assert(distance.to_s == '1 miglio')
  end

  def test_distance_miles_plural
    distance = Metar::Distance.new(10000, {:units => :miles, :decimals => 1})
    I18n.locale = :en
    assert(distance.to_s == '6.2 miles')
    I18n.locale = :it
    assert(distance.to_s == '6,2 miglia')
  end

end
