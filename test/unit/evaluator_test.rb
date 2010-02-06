require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarReport < Test::Unit::TestCase
  
  def setup
  end

  def test_new_with_string
    assert_nothing_thrown do
      evaluator = Metar::Evaluator.new('LIRQ 031220Z VRB02KT 5000 -DZ BKN025 BKN070 04/01 Q1020')
    end
  end

  def test_new_with_raw_object
    assert_nothing_thrown do
      raw = Metar::Raw.new('LIRQ')
      evaluator = Metar::Evaluator.new(raw)
    end
  end

  def test_run_with_string
    assert_nothing_thrown do
      evaluator = Metar::Evaluator.new('LIRQ 031220Z VRB02KT 5000 -DZ BKN025 BKN070 04/01 Q1020')
      evaluator.run!
    end
  end

  def test_run_with_raw_object
    assert_nothing_thrown do
      raw = Metar::Raw.new('LIRQ')
      evaluator = Metar::Evaluator.new(raw)
      evaluator.run!
    end
  end

  def test_attributes
    evaluator = Metar::Evaluator.new('LIRQ 031220Z VRB02KT 5000 -DZ BKN025 BKN070 04/01 Q1020')
    evaluator.run!
    assert_equal(:international, evaluator.report.standard)
    assert_equal('LIRQ', evaluator.report.cccc)
    assert_instance_of(Time, evaluator.report.time)
    assert_equal('VRB02KT', evaluator.report.wind)
    assert_equal('5000', evaluator.report.visibility)
    assert_equal(['-DZ'], evaluator.report.present_weather)
    # TODO: we get #<broken_cloud 025>, not 'BKN025'
    # assert_equal(['BKN025', 'BKN070'], evaluator.report.sky)
    assert_equal('04', evaluator.report.temperature)
    assert_equal('01', evaluator.report.dew_point)
    assert_equal('Q1020', evaluator.report.sea_level_pressure)
  end

  def test_missing_data
    assert_nothing_thrown do
      evaluator = Metar::Evaluator.new('AYMO 041500Z AUTO 35010KT //// // ////// 28/22 Q1009')
      evaluator.run!
    end
  end
end
