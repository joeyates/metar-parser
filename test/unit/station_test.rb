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

end
