# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

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
      @metar_time   = '10:56'
      @metar_datetime   = "#{@metar_date} #{@metar_time}"
      @station      = stub( 'station', :name    => 'Airport 1',
                                       :country => 'Wwwwww' )
      @parser       = stub( 'parser', :station_code => @station_code,
                                      :date         => Date.parse( @metar_date ),
                                      :time         => Time.parse( @metar_datetime ),
                                      :observer     => :real )
      Metar::Station.stub( :find_by_cccc ).with( @station_code ).and_return( @station )
    end

    subject { Metar::Report.new( @parser ) }

    after :each do
      I18n.locale = @locale
    end

    context '#date' do
      it 'formats the date' do
        expect(subject.date).to eq('06/05/2008')
      end
    end

    context '#time' do
      specify { subject.time.     should     == @metar_time }
    end

    context '#observer' do
      specify { subject.observer. should     == 'real' }
    end

    specify { subject.station_name.
                                  should     == 'Airport 1' }

    specify { subject.station_country.
                                  should     == 'Wwwwww' }

    specify { subject.station_code.
                                  should     == @station_code }

    context 'proxied from parser' do

      context 'singly' do
        [
          :wind,
          :variable_wind,
          :visibility,
          :minimum_visibility,
          :vertical_visibility,
          :temperature,
          :dew_point,
          :sea_level_pressure,
        ].each do | attribute |
          example attribute do
            @attr = stub( attribute.to_s )
            @parser.stub!( attribute => @attr )

            @attr.                   should_receive( :to_s )

            subject.send( attribute )
          end
        end

        context '#sky_summary' do

          it 'returns the summary' do
            @skies1 = stub('sky_conditions')
            @parser.stub!( :sky_conditions => [@skies1] )

            @skies1.              should_receive( :to_summary ).
                                  and_return( 'skies1' )

            subject.sky_summary.  should     == 'skies1'
          end

          it 'clear skies when missing' do
            @parser.stub!( :sky_conditions => [] )

            subject.sky_summary.  should     == 'clear skies'
          end

          it 'uses the last, if there is more than 1' do
            @skies1 = stub('sky_conditions1' )
            @skies2 = stub('sky_conditions2' )
            @parser.stub!( :sky_conditions => [ @skies1, @skies2 ] )

            @skies2.              should_receive( :to_summary ).
                                  and_return( 'skies2' )

            subject.sky_summary.  should     == 'skies2'
          end
        end
      end

      context 'joined' do

        it '#runway_visible_range' do
          @rvr1 = stub( 'rvr1', :to_s => 'rvr1' )
          @rvr2 = stub( 'rvr2', :to_s => 'rvr2' )
          @parser.stub!( :runway_visible_range => [ @rvr1, @rvr2 ] )

          subject.runway_visible_range.
                                  should     == 'rvr1, rvr2'
        end

        it '#present_weather' do
          @parser.stub!( :present_weather => [ 'pw1', 'pw2' ] )

          subject.present_weather.should     == 'pw1, pw2'
        end

        it '#remarks' do
          @parser.stub!( :remarks => [ 'rem1', 'rem2' ] )

          subject.remarks.        should     == 'rem1, rem2'
        end

        it '#sky_conditions' do
          sky1 = stub( 'sky1', :to_s => 'sky1' )
          sky2 = stub( 'sky2', :to_s => 'sky2' )
          @parser.stub!( :sky_conditions => [ sky1, sky2 ] )

          subject.sky_conditions. should     == 'sky1, sky2'
        end

      end

    end

    it '#to_s' do
      sky1 = stub( 'sky1', :to_summary => 'sky1' )
      sky2 = stub( 'sky2', :to_summary => 'sky2' )
      @parser.stub!( :wind            => 'wind',
                     :visibility      => 'visibility',
                     :minimum_visibility => 'min visibility',
                     :present_weather => ['pw'],
                     :sky_conditions  => [ sky1, sky2 ],
                     :temperature     => 'temp' )
      expected = <<EOT
name: Airport 1
country: Wwwwww
time: #{@metar_time}
wind: wind
visibility: visibility
minimum visibility: min visibility
weather: pw
sky: sky2
temperature: temp
EOT
      subject.to_s.               should     == expected
    end

  end

end

