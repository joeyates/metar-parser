# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Metar::VariableWind do

  context '.parse' do

    it 'understands nnn + V + nnn' do
      vw = Metar::VariableWind.parse( '090V180' )

      vw.direction1.value.        should     ==  90.0
      vw.direction2.value.        should     == 180.0
    end

    it 'accepts 360, rounding to 0 - 1' do
      vw = Metar::VariableWind.parse( '360V090' )

      vw.direction1.value.        should     ==   0.0
      vw.direction2.value.        should     ==  90.0
    end


    it 'accepts 360, rounding to 0 - 2' do
      vw = Metar::VariableWind.parse( '090V360' )

      vw.direction1.value.        should     ==  90.0
      vw.direction2.value.        should     ==   0.0
    end

    it 'returns nil for other' do
      vw = Metar::VariableWind.parse( 'XXX' )

      vw.                         should     be_nil
    end

  end

  context '#to_s' do

    it 'renders compatible values as compass directions' do
      vw = Metar::VariableWind.parse( '090V180' )

      vw.to_s.                    should     == 'E - S'
    end

  end

end

