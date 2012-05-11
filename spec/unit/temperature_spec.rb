load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

describe Metar::Temperature do

  context '.parse' do

    it 'understands numbers' do
      t = Metar::Temperature.parse( '5' )

      t.value.                    should     be_within( 0.01 ).of( 5.0 )
    end

    it 'treats an M-prefix as a negative indicator' do
      t = Metar::Temperature.parse( 'M5' )

      t.value.                    should     be_within( 0.01 ).of( -5.0 )
    end

    it 'returns nil for other values' do
      Metar::Temperature.parse('').
                                  should     be_nil
      Metar::Temperature.parse('aaa').
                                  should     be_nil
    end

  end

  context '#to_s' do

    it 'abbreviates the units' do
      t = Metar::Temperature.new( 5 )

      t.to_s.                     should     == '5°C'
    end

    it 'rounds to the nearest degree' do
      Metar::Temperature.new( 5.1 ).to_s.
                                  should     == '5°C'
      Metar::Temperature.new( 5.5 ).to_s.
                                  should     == '6°C'
    end

  end

end

