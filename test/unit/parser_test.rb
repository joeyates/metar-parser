require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarParser < Test::Unit::TestCase
  
  def setup
  end

  def test_new
    assert_nothing_thrown do
      raw = Metar::Parser.new(RAW_EXAMPLE)
    end
  end

end
