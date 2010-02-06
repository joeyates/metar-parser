#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarParser < Test::Unit::TestCase
  
  def setup
  end

  def test_us
    prs = Metar::Parser.parse(Metar::Lexer.lex('KSAN 021451Z 04003KT 4SM HZ FEW020 BKN200 12/09 A2986 RMK AO2 SLP110 T01170089 58006'))
    assert_instance_of(Dhaka::ParseSuccessResult, prs)
  end

  def test_int
    prs = Metar::Parser.parse(Metar::Lexer.lex('BIRK 021500Z 08011KT 9999 FEW051 SCT080 02/M05 Q1013'))
    assert_instance_of(Dhaka::ParseSuccessResult, prs)
  end

  def test_int_wind_speed_variable
    lex = Metar::Lexer.lex('LIRQ 031150Z VRB01KT 4000 -DZ BKN025 BKN070 03/01 Q1020')
    parser = Metar::Parser.parse(lex)
    assert_instance_of(Dhaka::ParseSuccessResult, parser)
  end

  def test_few_nnncc
    lex = Metar::Lexer.lex('AGGH 041400Z 00000KT 9999 HZ FEW016 FEW018CB SCT300 26/24 Q1005')
    parser = Metar::Parser.parse(lex)
    assert_instance_of(Dhaka::ParseSuccessResult, parser)
  end

  def test_visibility_in_km
    lex = Metar::Lexer.lex('ANAU 090200Z 12010KT 30KM FEW020 SCT050 31/27 Q1006')
    parser = Metar::Parser.parse(lex)
    assert_instance_of(Dhaka::ParseSuccessResult, parser)
  end

  def test_missing_data
    lex = Metar::Lexer.lex('AYMO 041500Z AUTO 35010KT //// // ////// 28/22 Q1009')
    parser = Metar::Parser.parse(lex)
    assert_instance_of(Dhaka::ParseSuccessResult, parser)
  end

  def test_drifting_snow
    lex = Metar::Lexer.lex('CYUB 041600Z 27013KT 10SM DRSN FEW030 M32/M37 A3007 RMK SC2 VIA CZNB SLP183')
    parser = Metar::Parser.parse(lex)
    assert_instance_of(Dhaka::ParseSuccessResult, parser)
  end

  def test_overcast
    lex = Metar::Lexer.lex('CYYT 041600Z 04009KT 10SM -SHSN OVC020 M09/M12 A2964 RMK SC8 SLP047')
    parser = Metar::Parser.parse(lex)
    assert_instance_of(Dhaka::ParseSuccessResult, parser)
  end

end
