load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

describe Metar::Parser do

  context 'attributes' do

    it 'time obligatory' do
      expect do
        setup_parser('PAIL', "2010/02/06 16:10\nPAIL 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000") 
      end.       to         raise_error( Metar::ParseError )
    end

    it 'date' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.date.    should     == Date.new(2010, 2, 6)
    end

    it 'observer_real' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.observer.    should     == :real
    end

    it 'wind' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.wind.direction.value.   should  be_within( 0.0001 ).of( 240 )
      parser.wind.speed.to_knots.   should  be_within( 0.0001 ).of( 6 )
    end

    it 'variable_wind' do
      parser = setup_parser('LIRQ', "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005")
      parser.variable_wind.direction1.value.should be_within( 0.0001 ).of( 350 )
      parser.variable_wind.direction2.value.should be_within( 0.0001 ).of( 50 )
    end

    it 'visibility_miles_and_fractions' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.visibility.distance.to_miles. should be_within( 0.01 ).of( 1.75 )
    end

    it 'runway_visible_range' do
      parser = setup_parser('ESSB', "2010/02/15 10:20\nESSB 151020Z 26003KT 2000 R12/1000N R30/1500N VV002 M07/M07 Q1013 1271//55")
      parser.runway_visible_range.length.    should     == 2
      parser.runway_visible_range[0].designator.    should     == '12'
      parser.runway_visible_range[0].visibility1.distance.value.    should     == 1000
      parser.runway_visible_range[0].tendency.    should     == :no_change
    end

    it 'runway_visible_range_defaults_to_empty_array' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.runway_visible_range.length.    should     == 0
    end

    it 'runway_visible_range_variable' do
      parser = setup_parser('KPDX', "2010/02/15 11:08\nKPDX 151108Z 11006KT 1/4SM R10R/1600VP6000FT FG OVC002 05/05 A3022 RMK AO2")

      parser.runway_visible_range[0].visibility1.distance.to_feet.    should     == 1600.0
      parser.runway_visible_range[0].visibility2.distance.to_feet.    should     == 6000.0
    end

    it 'present_weather' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.present_weather.length.    should     == 1
      parser.present_weather[0].modifier.    should     == 'light'
      parser.present_weather[0].phenomenon.    should     == 'snow'
    end

    it 'present_weather_defaults_to_empty_array' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.present_weather.length.    should     == 0
    end

    it 'sky_conditions' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.sky_conditions.length.    should     == 2
      parser.sky_conditions[0].quantity.    should     == 'broken'
      parser.sky_conditions[0].height.value.    should     == 480
      parser.sky_conditions[1].quantity.    should     == 'overcast'
      parser.sky_conditions[1].height.value.    should     == 900
    end

    it 'sky_conditions_defaults_to_empty_array' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN M17/M20 A2910 RMK AO2 P0000")
      parser.sky_conditions.length.    should     == 0
    end

    it 'vertical_visibility' do
      parser = setup_parser('CYXS', "2010/02/15 10:34\nCYXS 151034Z AUTO 09003KT 1/8SM FZFG VV001 M03/M03 A3019 RMK SLP263 ICG")
      parser.vertical_visibility.value.    should     == 30
    end

    it 'temperature_obligatory' do
      expect do
        setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 A2910 RMK AO2 P0000")
      end.       to         raise_error( Metar::ParseError )
    end

    it 'temperature' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.temperature.value.    should     == -17
    end

    it 'dew_point' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.dew_point.value.    should     == -20
    end

    it 'sea_level_pressure' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.sea_level_pressure.to_inches_of_mercury.    should     == 29.10
    end

    it 'remarks' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000")
      parser.remarks.   should be_a Array
      parser.remarks.length.    should     == 2
      parser.remarks[0].    should     == 'AO2'
      parser.remarks[1].    should     == 'P0000'
    end

    it 'remarks_defaults_to_empty_array' do
      parser = setup_parser('PAIL', "2010/02/06 16:10\nPAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910")
      parser.remarks.   should be_a Array
      parser.remarks.length.    should     == 0
    end
  
    def setup_parser( cccc, metar )
      raw = Metar::Raw.new( cccc, metar )
      Metar::Parser.new( raw )
    end

  end

end

