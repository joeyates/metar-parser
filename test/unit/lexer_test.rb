require File.dirname(__FILE__) + '/../metar_test_helper'

class TestMetarLexer < Test::Unit::TestCase
  
  def setup
  end

  def test_int_lexing
    lex = Metar::Lexer.lex('BIRK 021500Z 08011KT 9999 FEW051 SCT080 02/M05 Q1013')
    tokens = lex.collect { |token| token }
    assert_equal 9, tokens.length
    assert_equal nil, tokens[-1].value
    assert_equal '021500Z', tokens[1].value
  end
end
