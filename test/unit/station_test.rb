#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestStation < Test::Unit::TestCase
  
  def setup
  end

  def test_class_method_exist_on_existing_station
    assert Metar::Station.exist?('LIRQ')
  end

  def test_class_method_exist_on_non_existant_station
    assert (not Metar::Station.exist?('X'))
  end

  def test_find_by_cccc_on_existing_station
    assert_not_nil Metar::Station.find_by_cccc('LIRQ')
  end

  def test_find_by_cccc_works_after_station_all
    Metar::Station.all
    assert_not_nil Metar::Station.find_by_cccc('LIRQ')
  end

  def test_instantiation_sets_cccc
    station = Metar::Station.new('LIRQ')
    assert_equal 'LIRQ', station.cccc
  end

  def test_simple_instantiation_doesnt_cause_loading
    station = Metar::Station.new('LIRQ')
    assert (not station.loaded?)
  end

  def test_calling_attributes_causes_loading
    station = Metar::Station.new('LIRQ')
    station.name
    assert station.loaded?
  end

  def test_latitude_is_a_decimal_number
    station = Metar::Station.new('LIRQ')
    assert station.latitude.to_s == station.latitude.to_f.to_s
  end

  def test_longitude_is_a_decimal_number
    station = Metar::Station.new('LIRQ')
    assert station.longitude.to_s == station.longitude.to_f.to_s
  end

  def test_to_latitude_north
    assert(Metar::Station.to_latitude('43-48N') == 43.8)
  end

  def test_to_latitude_south
    assert(Metar::Station.to_latitude('43-48S') == -43.8)
  end

  def test_to_longitude_east
    assert(Metar::Station.to_longitude('011-12E') == 11.2)
  end

  def test_to_longitude_west
    assert(Metar::Station.to_longitude('011-12W') == -11.2)
  end
end
