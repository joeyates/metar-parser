# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Metar::Parser do

  context '.for_cccc' do

    it 'returns a loaded parser' do
      station = stub( 'station' )
      raw = stub( 'raw', :metar => "XXXX 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000",
                         :time  => '2010/02/06 16:10' )
      Metar::Station.stub!( :new => station )
      Metar::Raw::Noaa.stub!( :new => raw )

      parser = Metar::Parser.for_cccc( 'XXXX' )

      parser.                     should     be_a( Metar::Parser )
      parser.station_code.        should     == 'XXXX'
    end
         
  end

  context 'attributes' do

    before :each do
      @call_time = Time.parse('2011-05-06 16:35')
      Time.stub!(:now).and_return(@call_time)
    end

    it '.location missing' do
      expect do
        setup_parser("FUBAR 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000") 
      end.                        to         raise_error( Metar::ParseError, /Expecting location/ )
    end

    it '.time missing' do
      expect do
        setup_parser("PAIL 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000") 
      end.                        to         raise_error( Metar::ParseError, /Expecting datetime/ )
    end

    it 'time' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

      parser.time.                should     == Time.gm(2011, 05, 06, 16, 10)
    end

    context '.observer' do

      it 'real' do
        parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

        parser.observer.          should     == :real
      end

      it 'auto' do
        parser = setup_parser("CYXS 151034Z AUTO 09003KT 1/8SM FZFG VV001 M03/M03 A3019 RMK SLP263 ICG")

        parser.observer.          should     == :auto
      end

      it 'corrected' do
        parser = setup_parser("PAIL 061610Z COR 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

        parser.observer.          should     == :corrected
      end

      it 'corrected (Canadian)' do
        parser = setup_parser('CYZU 310100Z CCA 26004KT 15SM FEW009 BKN040TCU BKN100 OVC210 15/12 A2996 RETS RMK SF1TCU4AC2CI1 SLP149')

        parser.observer.          should     == :corrected
      end
      
    end

    it 'wind' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

      parser.wind.direction.value.should     be_within( 0.0001 ).of( 240 )
      parser.wind.speed.to_knots. should     be_within( 0.0001 ).of( 6 )
    end

    it 'variable_wind' do
      parser = setup_parser("LIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")

      parser.variable_wind.direction1.value.
                                  should     be_within( 0.0001 ).of( 350 )
      parser.variable_wind.direction2.value.
                                  should     be_within( 0.0001 ).of( 50 )
    end

    context '.visibility' do
      it 'CAVOK' do
        parser = setup_parser("PAIL 061610Z 24006KT CAVOK M17/M20 A2910 RMK AO2 P0000")

        parser.visibility.distance.value.
                                  should     be_within( 0.01 ).of( 10000.00 )
        parser.visibility.comparator.
                                  should     == :more_than
        parser.present_weather.size.
                                  should     == 1
        parser.present_weather[ 0 ].phenomenon.
                                  should     == 'No significant weather'
        parser.sky_conditions.size.
                                  should     == 1
        parser.sky_conditions[ 0 ].type.
                                  should     == nil
      end

      it 'visibility_miles_and_fractions' do
        parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

        parser.visibility.distance.to_miles.
                                  should     be_within( 0.01 ).of( 1.75 )
      end

      it 'in meters' do
        parser = setup_parser('VABB 282210Z 22005KT 4000 HZ SCT018 FEW025TCU BKN100 28/25 Q1003 NOSIG')

        parser.visibility.distance.value.
                                  should     be_within(0.01).of(4000)
       end

      it '//// with automatic observer' do
        parser = setup_parser("CYXS 151034Z AUTO 09003KT //// FZFG VV001 M03/M03 A3019 RMK SLP263 ICG")

        parser.visibility.        should     be_nil
      end
    end

    it 'runway_visible_range' do
      parser = setup_parser("ESSB 151020Z 26003KT 2000 R12/1000N R30/1500N VV002 M07/M07 Q1013 1271//55")
      parser.runway_visible_range.length.
                                  should     == 2
      parser.runway_visible_range[0].designator.
                                  should     == '12'
      parser.runway_visible_range[0].visibility1.distance.value.
                                  should     == 1000
      parser.runway_visible_range[0].tendency.
                                  should     == :no_change
    end

    it 'runway_visible_range_defaults_to_empty_array' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

      parser.runway_visible_range.length.
                                  should     == 0
    end

    it 'runway_visible_range_variable' do
      parser = setup_parser("KPDX 151108Z 11006KT 1/4SM R10R/1600VP6000FT FG OVC002 05/05 A3022 RMK AO2")

      parser.runway_visible_range[0].visibility1.distance.to_feet.
                                  should     == 1600.0
      parser.runway_visible_range[0].visibility2.distance.to_feet.
                                  should     == 6000.0
    end

    context '.present_weather' do

      it 'normal' do
        parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

        parser.present_weather.size.
                                  should     == 1
        parser.present_weather[0].modifier.
                                  should     == 'light'
        parser.present_weather[0].phenomenon.
                                  should     == 'snow'
      end

      it 'auto + //' do
        parser = setup_parser("PAIL 061610Z AUTO 24006KT 1 3/4SM // BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

        parser.present_weather.size.
                                  should     == 1
        parser.present_weather[0].phenomenon.
                                  should     == 'not observed'
      end

    end

    it 'present_weather_defaults_to_empty_array' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.present_weather.length.
                                  should     == 0
    end

    context '.sky_conditions' do

      it 'normal' do
        parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

        parser.sky_conditions.size.
                                  should     == 2
        parser.sky_conditions[0].quantity.
                                  should     == 'broken'
        parser.sky_conditions[0].height.value.
                                  should     == 487.68
        parser.sky_conditions[1].quantity.
                                  should     == 'overcast'
        parser.sky_conditions[1].height.value.
                                  should     == 914.40
      end

      it 'auto + ///' do
        parser = setup_parser("PAIL 061610Z AUTO 24006KT 1 3/4SM /// M17/M20 A2910 RMK AO2 P0000")

        parser.sky_conditions.size.
                                  should     == 0
      end

    end

    it 'sky_conditions_defaults_to_empty_array' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN M17/M20 A2910 RMK AO2 P0000")
      parser.sky_conditions.length.
                                  should     == 0
    end

    it 'vertical_visibility' do
      parser = setup_parser("CYXS 151034Z AUTO 09003KT 1/8SM FZFG VV001 M03/M03 A3019 RMK SLP263 ICG")
      parser.vertical_visibility.value.
                                  should     == 30.48
    end

    it 'temperature' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.temperature.value.   should     == -17
    end

    it 'dew_point' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.dew_point.value.     should     == -20
    end

    it 'sea_level_pressure' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.sea_level_pressure.to_inches_of_mercury.
                                  should     == 29.10
    end

    it 'recent weather' do
      parser = setup_parser("CYQH 310110Z 00000KT 20SM SCT035CB BKN050 RETS RMK CB4SC1")

      parser.recent_weather.      should    be_a Array
      parser.recent_weather.size. should    == 1
      parser.recent_weather[0].phenomenon.
                                  should    == 'thunderstorm'
    end

    it 'remarks' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")

      parser.remarks.             should     be_a Array
      parser.remarks.length.      should     == 2
      parser.remarks[0].          should     == 'AO2'
      parser.remarks[1].          should     == 'P0000'
    end

    it 'remarks_defaults_to_empty_array' do
      parser = setup_parser("PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910")

      parser.remarks.             should     be_a Array
      parser.remarks.length.      should     == 0
    end
  
    def setup_parser(metar)
      raw = Metar::Raw::Data.new(metar)
      Metar::Parser.new(raw)
    end

  end

end

