require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarReport < Test::Unit::TestCase
  
  def setup
  end

  def test_from_string
    evaluator = Metar::Evaluator.new('LIRQ 031220Z VRB02KT 5000 -DZ BKN025 BKN070 04/01 Q1020')
    evaluator.run!
    report = evaluator.report
    assert_instance_of(Metar::Report, report)
    assert_equal('LIRQ', report.cccc)
    assert_instance_of(Time, report.time)
    assert_equal('04', report.temperature)
    assert_equal('Firenze / Peretola', report.name)
  end

  def test_raw
    raw = Metar::Raw.new('LIRQ')
    evaluator = Metar::Evaluator.new(raw)
    evaluator.run!
    report = evaluator.report
    assert_equal('LIRQ', report.cccc)
  end

end
