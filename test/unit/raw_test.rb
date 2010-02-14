#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarRaw < Test::Unit::TestCase
  
  def setup
  end

  def test_fetch
    raw = Metar::Raw.fetch('LIRQ')
    assert_instance_of(String, raw)
  end

  def test_new
    assert_nothing_thrown do
      raw = Metar::Raw.new('LIRQ')
    end
  end

  def test_attributes
    raw = Metar::Raw.new('LIRQ')
    assert_equal('LIRQ', raw.cccc)
    assert_instance_of(Time, raw.time)
    assert_instance_of(String, raw.metar)
  end

end
