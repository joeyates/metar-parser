load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

RSpec::Matchers.define :be_wind do | direction, speed, gusts |
  match do | wind |
    if wind.nil?              != [ direction, speed, gusts ].all?( &:nil? )
      false
    elsif wind.direction.nil? != direction.nil?
      false
    elsif wind.speed.nil?     != speed.nil?
      false
    elsif direction.is_a?( Symbol )         && wind.direction != direction
      false
    elsif direction.is_a?( M9t::Direction ) && (wind.direction.value - direction).abs > 0.01
      false
    elsif speed.is_a?( Symbol )             && wind.speed     != speed
       false
    elsif speed.is_a?( Metar::Speed )       && (wind.speed.value - speed).abs > 0.01
      false
    elsif ! wind.gusts.nil?                 && (wind.gusts.value     - gusts    ).abs > 0.01
       false
    else
      true
    end
  end
end

describe Metar::Wind do

  context '.parse' do

    it 'treats 5 digits as degrees and kilometers per hour' do
      Metar::Wind.parse( '12345' ).
                                  should     be_wind(  123.0, 12.5, nil )
    end

    it 'understands 5 digits + MPS' do
      Metar::Wind.parse( '12345MPS' ).
                                  should     be_wind( 123.0, 45.0, nil )
    end

    it 'understands 5 digits + KMH' do
      Metar::Wind.parse( '12345KMH' ).
                                  should     be_wind( 123.0, 12.5, nil )
    end

    it 'understands 5 digits + KT' do
      Metar::Wind.parse( '12345KT' ).
                                  should     be_wind( 123.0, 23.15, nil )
    end

    it 'returns nil for directions outside 0 to 360' do
      Metar::Wind.parse( '88845KT' ).
                                  should     be_nil
    end

    it 'understands 5 digits + G + 2 digits' do
      Metar::Wind.parse( '12345G67' ).
                                  should     be_wind( 123.0, 12.5, 18.61 )
    end

    it 'understands 5 digits + G + 2 digits + MPS' do
      Metar::Wind.parse( '12345G67MPS' ).
                                  should     be_wind( 123.0, 45.0, 67.00 )
    end

    it 'understands 5 digits + G + 2 digits + KMH' do
      Metar::Wind.parse( '12345G67KMH' ).
                                  should     be_wind( 123.0, 12.5, 18.61 )
    end

    it 'understands 5 digits + G + 2 digits + KT' do
      Metar::Wind.parse( '12345G67KT' ).
                                  should     be_wind( 123.0, 23.15, 34.47 )
    end

    it 'understands VRB + 2 digits' do
      Metar::Wind.parse( 'VRB12' ).
                                  should     be_wind( :variable_direction, 3.33, nil )
    end

    it 'understands VRB + 2 digits + KMH' do
      Metar::Wind.parse( 'VRB12KMH' ).
                                  should     be_wind( :variable_direction, 3.33, nil )
    end

    it 'understands VRB + 2 digits + MPS' do
      Metar::Wind.parse( 'VRB12MPS' ).
                                  should     be_wind( :variable_direction, 12.00, nil )
    end

    it 'understands VRB + 2 digits + KT' do
      Metar::Wind.parse( 'VRB12KT' ).
                                  should     be_wind( :variable_direction, 6.17, nil )
    end

    it 'understands /// + 2 digits' do
      Metar::Wind.parse( '///12' ).
                                  should     be_wind( :unknown_direction,  3.33, nil )
    end

    it 'understands /// + 2 digits + KMH' do
      Metar::Wind.parse( '///12KMH' ).
                                  should     be_wind( :unknown_direction,  3.33, nil )
    end

    it 'understands /// + 2 digits + MPS' do
      Metar::Wind.parse( '///12MPS' ).
                                  should     be_wind( :unknown_direction, 12.00, nil )
    end

    it 'understands /// + 2 digits + KT' do
      Metar::Wind.parse( '///12KT' ).
                                  should     be_wind( :unknown_direction,  6.17, nil )
    end

    it 'understands /////' do
      Metar::Wind.parse( '/////' ).
                                  should     be_wind( :unknown_direction, :unknown, nil )
    end

    it 'returns nil for badly formatted values' do
      Metar::Wind.parse( 'XYZ12KT' ).
                                  should     be_nil
    end

    it 'returns nil for nil' do
      Metar::Wind.parse( nil ).   should     be_nil
    end

  end

  context '#to_s' do

    it 'should return a String version'

  end

end

