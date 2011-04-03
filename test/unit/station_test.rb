#!/usr/bin/env ruby

require 'metar_test_helper'

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

  def test_to_latitude_incorrect_gives_nil
    assert_nil Metar::Station.to_latitude('23-15')
  end

  def test_to_latitude_n
    assert_equal 43.8, Metar::Station.to_latitude('43-48N')
  end

  def test_to_latitude_s
    assert_equal -23.25, Metar::Station.to_latitude('23-15S')
  end

  def test_to_longitude_e
    assert_equal 11.2, Metar::Station.to_longitude('11-12E')
  end

  def test_to_longitude_w
    assert_equal -11.2, Metar::Station.to_longitude('11-12W')
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

  def test_name
    station = Metar::Station.new('LIRQ')
    assert_equal 'Firenze / Peretola', station.name
  end

  def test_state
    station = Metar::Station.new('LIRQ')
    assert_equal '', station.state
  end

  def test_country
    station = Metar::Station.new('LIRQ')
    assert_equal 'Italy', station.country
  end

  def test_latitude_is_a_decimal_number
    station = Metar::Station.new('LIRQ')
    assert_equal station.latitude.to_s, station.latitude.to_f.to_s
  end

  def test_longitude_is_a_decimal_number
    station = Metar::Station.new('LIRQ')
    assert_equal station.longitude.to_s, station.longitude.to_f.to_s
  end

end
