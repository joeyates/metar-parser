#!/usr/bin/env ruby
# encoding: utf-8

$:.unshift( File.expand_path( '..', File.dirname( __FILE__ ) ) )
require 'metar_test_helper'

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

  def test_cccc
    raw = Metar::Raw.new('LIRQ')
    assert_equal('LIRQ', raw.cccc)
  end

  def test_time
    raw = Metar::Raw.new('LIRQ')
    assert_instance_of(Time, raw.time)
    assert_equal(2010, raw.time.year)
  end

  def test_metar
    raw = Metar::Raw.new('LIRQ')
    assert_instance_of(String, raw.metar)
  end

end
