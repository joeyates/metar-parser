# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Metar::Pressure do

  context '.parse' do

    it 'interprets the Q prefix as hectopascals' do
      Metar::Pressure.parse( 'Q1300' ).value.
                                  should     be_within( 0.01 ).of( 1.3 )
    end

    it 'interprets the A prefix as inches of mercury' do
      Metar::Pressure.parse( 'A1234' ).value.
                                  should     be_within( 0.01 ).of( 0.42 )
    end

    it 'require 4 digits' do
      Metar::Pressure.parse( 'Q12345' ).
                                  should     be_nil
      Metar::Pressure.parse( 'A123' ).
                                  should     be_nil
    end

    it 'returns nil for nil' do
      Metar::Pressure.parse( nil ).
                                  should     be_nil
    end

  end

end

