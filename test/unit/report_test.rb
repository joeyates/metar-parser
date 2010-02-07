#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarReport < Test::Unit::TestCase
  
  def setup
  end

  def test_new
    assert_nothing_thrown do
      raw = Metar::Raw.new('LIRQ')
      report = Metar::Report.new(raw)
      $stderr.puts report.inspect
    end
  end
end
