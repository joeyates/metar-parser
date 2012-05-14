load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

describe Metar::Report do

  context 'initialization' do
    
    it 'loads the Station' do
      station = stub( 'station' )
      parser = stub( 'parser', :station_code => 'SSSS' )

      Metar::Station.             should_receive( :find_by_cccc ).
                                  with( 'SSSS' ).
                                  and_return( station )

      Metar::Report.new( parser )
    end
    
  end

  context 'attributes' do

    before :each do
      @locale       = I18n.locale
      @station_code = 'SSSS'
      @metar_date   = '2008/05/06'
      @metar_time   = "#{@metar_date} 10:56"
      @station      = stub( 'station' )
      @parser       = stub( 'parser', :station_code => @station_code,
                                      :date         => Date.parse( @metar_date ),
                                      :time         => Time.parse( @metar_time ),
                                      :observer     => :real )
      Metar::Station.stub( :find_by_cccc ).with( @station_code ).and_return( @station )
    end

    subject { Metar::Report.new( @parser ) }

    after :each do
      I18n.locale = @locale
    end

    context '#date' do

      it 'localizes' do
        I18n.locale = :en

        subject.date.             should     == '06/05/2008'

        I18n.locale = :it

        subject.date.             should     == '06/05/2008'
      end

    end

    context '#time' do
      specify { subject.time.     should     == '10:56' }
    end

    context '#observer' do
      specify { subject.observer. should     == 'real' }
    end

    it 'other'

  end

end

