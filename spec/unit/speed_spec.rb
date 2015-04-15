require "spec_helper"

describe Metar::Speed do
  context '.parse' do
    it 'returns nil for nil' do
      speed = Metar::Speed.parse( nil )

      expect(speed).to be_nil
    end

    it 'parses knots' do
      speed = Metar::Speed.parse( '5KT' )

      expect(speed).to be_a( Metar::Speed )
      expect(speed.value).to be_within( 0.01 ).of( 2.57 )
    end

    it 'parses meters per second' do
      speed = Metar::Speed.parse( '7MPS' )

      expect(speed).to be_a( Metar::Speed )
      expect(speed.value).to be_within( 0.01 ).of( 7.00 )
    end

    it 'parses kilometers per hour' do
      speed = Metar::Speed.parse( '14KMH' )

      expect(speed).to be_a( Metar::Speed )
      expect(speed.value).to be_within( 0.01 ).of( 3.89 )
    end

    it 'trates straight numbers as kilomters per hour' do
      speed = Metar::Speed.parse( '14' )

      expect(speed).to be_a( Metar::Speed )
      expect(speed.value).to be_within( 0.01 ).of( 3.89 )
    end

    it 'returns nil for other strings' do
      speed = Metar::Speed.parse( '' )

      expect(speed).to be_nil
    end
  end
end
