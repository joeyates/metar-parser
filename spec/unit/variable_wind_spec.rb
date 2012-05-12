load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

describe Metar::VariableWind do

  context '.parse' do

    it 'understands nnn + V + nnn' do
      vw = Metar::VariableWind.parse( '090V180' )

      vw.direction1.value.        should     ==  90.0
      vw.direction2.value.        should     == 180.0
    end

    it 'returns nil for other' do
      vw = Metar::VariableWind.parse( 'XXX' )

      vw.                         should     be_nil
    end

  end

  context '#to_s' do

    it 'renders the ' do
      vw = Metar::VariableWind.parse( '090V180' )

      vw.to_s.                    should     == 'E - S'
    end

  end

end

