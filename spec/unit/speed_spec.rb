# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Metar::Speed do

  context '.parse' do

    it 'returns nil for nil' do
      speed = Metar::Speed.parse( nil )

      speed.                      should     be_nil
    end

    it 'parses knots' do
      speed = Metar::Speed.parse( '5KT' )

      speed.                      should     be_a( Metar::Speed )
      speed.value.                should     be_within( 0.01 ).of( 2.57 )
    end

    it 'parses meters per second' do
      speed = Metar::Speed.parse( '7MPS' )

      speed.                      should     be_a( Metar::Speed )
      speed.value.                should     be_within( 0.01 ).of( 7.00 )
    end

    it 'parses kilometers per hour' do
      speed = Metar::Speed.parse( '14KMH' )

      speed.                      should     be_a( Metar::Speed )
      speed.value.                should     be_within( 0.01 ).of( 3.89 )
    end

    it 'trates straight numbers as kilomters per hour' do
      speed = Metar::Speed.parse( '14' )

      speed.                      should     be_a( Metar::Speed )
      speed.value.                should     be_within( 0.01 ).of( 3.89 )
    end

    it 'returns nil for other strings' do
      speed = Metar::Speed.parse( '' )

      speed.                      should     be_nil
    end

  end

end

