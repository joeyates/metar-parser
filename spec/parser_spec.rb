# frozen_string_literal: true

require 'spec_helper'

require 'timecop'

describe Metar::Parser do
  after do
    Metar::Parser.compliance = :loose
  end

  context '.for_cccc' do
    let(:station) { double(Metar::Station) }
    let(:raw) { double(Metar::Raw::Noaa, metar: metar, time: time) }
    let(:metar) do
      "XXXX 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
        "RMK AO2 P0000"
    end
    let(:time) { Time.gm(2010, 2, 6) }

    before do
      allow(Metar::Station).to receive(:new) { station }
      allow(Metar::Raw::Noaa).to receive(:new) { raw }
    end

    it 'returns a loaded parser' do
      parser = Metar::Parser.for_cccc('XXXX')

      expect(parser).to be_a(Metar::Parser)
      expect(parser.station_code).to eq('XXXX')
    end
  end

  context 'attributes' do
    let(:call_time) { Time.parse('2011-05-06 16:35') }

    before { Timecop.freeze(call_time) }
    after { Timecop.return }

    context 'with location missing' do
      let(:missing_location) do
        "FUBAR 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000"
      end

      it 'fails' do
        expect do
          setup_parser(missing_location)
        end.to raise_error(Metar::ParseError, /Expecting location/)
      end
    end

    context 'datetime' do
      it 'is parsed' do
        parser = setup_parser(
          "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
            "RMK AO2 P0000"
        )

        expect(parser.time).to eq(Time.gm(2011, 5, 6, 16, 10))
      end

      it 'throws an error is missing' do
        expect do
          setup_parser(
            "PAIL 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000"
          )
        end.to raise_error(Metar::ParseError, /Expecting datetime/)
      end

      context 'across a month rollover' do
        let(:time)  { Time.gm(2016, 3, 31, 23, 59) }
        let(:metar) { "OPPS 312359Z 23006KT 4000 HZ SCT040 SCT100 17/12 Q1011" }
        let(:raw) { double(Metar::Raw, metar: metar, time: time) }
        let(:call_time) { Time.parse("2016/04/01 00:02:11 PDT") }

        subject { described_class.new(raw) }

        it 'has the correct date' do
          expect(subject.time.year).to eq(2016)
          expect(subject.time.month).to eq(3)
          expect(subject.time.day).to eq(31)
        end
      end

      context 'in strict mode' do
        before do
          Metar::Parser.compliance = :strict
        end

        it 'less than 6 numerals fails' do
          expect do
            setup_parser('MMCE 21645Z 12010KT 8SM SKC 29/26 A2992 RMK')
          end.to raise_error(Metar::ParseError, /Expecting datetime/)
        end
      end

      context 'in loose mode' do
        it '5 numerals parses' do
          parser = setup_parser('MMCE 21645Z 12010KT 8SM SKC 29/26 A2992 RMK')

          expect(parser.time).to eq(Time.gm(2011, 5, 2, 16, 45))
        end

        it "with 4 numerals parses, takes today's day" do
          parser = setup_parser('HKML 1600Z 19010KT 9999 FEW022 25/22 Q1015')

          expect(parser.time).to eq(Time.gm(2011, 5, 6, 16, 0))
        end
      end
    end

    context '.observer' do
      it 'real' do
        parser = setup_parser(
          "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
            "RMK AO2 P0000"
        )

        expect(parser.observer.value).to eq(:real)
      end

      it 'auto' do
        parser = setup_parser(
          "CYXS 151034Z AUTO 09003KT 1/8SM FZFG VV001 M03/M03 A3019 " \
            "RMK SLP263 ICG"
        )

        expect(parser.observer.value).to eq(:auto)
      end

      it 'corrected' do
        parser = setup_parser(
          "PAIL 061610Z COR 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
            "RMK AO2 P0000"
        )

        expect(parser.observer.value).to eq(:corrected)
      end

      it 'corrected (Canadian, first correction)' do
        parser = setup_parser(
          "CYZU 310100Z CCA 26004KT 15SM " \
            "FEW009 BKN040TCU BKN100 OVC210 15/12 A2996 RETS " \
            "RMK SF1TCU4AC2CI1 SLP149"
        )

        expect(parser.observer.value).to eq(:corrected)
      end

      it 'corrected (Canadian, second correction)' do
        parser = setup_parser(
          "CYCX 052000Z CCB 30014G27KT 15SM DRSN SCT035 M02/M09 A2992 " \
            "RMK SC4 SLP133"
        )

        expect(parser.observer.value).to eq(:corrected)
      end

      it 'corrected (Canadian, rare third correction)' do
        parser = setup_parser(
          "CYEG 120000Z CCC 12005KT 15SM FEW110 BKN190 03/M01 A2980 " \
            "RMK AC2AC3 SLP122"
        )

        expect(parser.observer.value).to eq(:corrected)
      end
    end

    context 'wind' do
      it 'is parsed' do
        parser = setup_parser(
          "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
            "RMK AO2 P0000"
        )

        expect(parser.wind.direction.value).to be_within(0.0001).of(240)
        expect(parser.wind.speed.to_knots).to be_within(0.0001).of(6)
      end

      context 'in strict mode' do
        before do
          Metar::Parser.compliance = :strict
        end

        it 'more than 5 digits fails' do
          expect do
            setup_parser('KSEE 181947Z 000000KT 10SM SKC 22/10 A2999')
          end.to raise_error(Metar::ParseError, /Unparsable/)
        end
      end

      context 'in loose mode' do
        it 'more than 5 digits is parsed' do
          parser = setup_parser('KSEE 181947Z 000000KT 10SM SKC 22/10 A2999')
          expect(parser.wind.direction.value).to eq(0.0)
          expect(parser.visibility.distance.value).to be_within(1).of(16_093)
        end
      end
    end

    it 'variable_wind' do
      parser = setup_parser(
        "LIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005"
      )

      expect(parser.variable_wind.direction1.value).to be_within(0.0001).of(350)
      expect(parser.variable_wind.direction2.value).to be_within(0.0001).of(50)
    end

    context '.visibility' do
      it 'CAVOK' do
        parser = setup_parser(
          "PAIL 061610Z 24006KT CAVOK M17/M20 A2910 RMK AO2 P0000"
        )

        expect(parser.visibility.distance.value).
          to be_within(0.01).of(10_000.00)
        expect(parser.visibility.comparator).to eq(:more_than)
        expect(parser.present_weather.size).to eq(1)
        expect(parser.present_weather[0].phenomenon).
          to eq('No significant weather')
        expect(parser.sky_conditions.size).to eq(1)
        expect(parser.sky_conditions[0].type).to eq(nil)
      end

      it 'visibility_miles_and_fractions' do
        parser = setup_parser(
          "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
            "RMK AO2 P0000"
        )

        expect(parser.visibility.distance.to_miles).to be_within(0.01).of(1.75)
      end

      it 'in meters' do
        parser = setup_parser(
          "VABB 282210Z 22005KT 4000 HZ SCT018 " \
            "FEW025TCU BKN100 28/25 Q1003 NOSIG"
        )

        expect(parser.visibility.distance.value).to be_within(0.01).of(4000)
      end

      it '//// with automatic observer' do
        parser = setup_parser(
          "CYXS 151034Z AUTO 09003KT //// FZFG VV001 M03/M03 A3019 " \
            "RMK SLP263 ICG"
        )

        expect(parser.visibility).to be_nil
      end
    end

    it 'runway_visible_range' do
      parser = setup_parser(
        "ESSB 151020Z 26003KT 2000 R12/1000N R30/1500N VV002 M07/M07 " \
          "Q1013 1271//55"
      )
      expect(parser.runway_visible_range.size).to eq(2)
      expect(parser.runway_visible_range[0].designator).to eq('12')
      expect(parser.runway_visible_range[0].visibility1.distance.value).
        to eq(1000)
      expect(parser.runway_visible_range[0].tendency).to eq(:no_change)
    end

    it 'runway_visible_range_defaults_to_empty_array' do
      parser = setup_parser(
        "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
          "RMK AO2 P0000"
      )

      expect(parser.runway_visible_range.size).to eq(0)
    end

    it 'runway_visible_range_variable' do
      parser = setup_parser(
        "KPDX 151108Z 11006KT 1/4SM R10R/1600VP6000FT FG OVC002 05/05 A3022 " \
          "RMK AO2"
      )

      expect(parser.runway_visible_range[0].visibility1.distance.to_feet).
        to eq(1600.0)
      expect(parser.runway_visible_range[0].visibility2.distance.to_feet).
        to eq(6000.0)
    end

    context '.present_weather' do
      it 'normal' do
        parser = setup_parser(
          "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
            "RMK AO2 P0000"
        )

        expect(parser.present_weather.size).to eq(1)
        expect(parser.present_weather[0].modifier).to eq('light')
        expect(parser.present_weather[0].phenomenon).to eq('snow')
      end

      it 'auto + //' do
        parser = setup_parser(
          "PAIL 061610Z AUTO 24006KT 1 3/4SM // BKN016 OVC030 M17/M20 A2910 " \
            "RMK AO2 P0000"
        )

        expect(parser.present_weather.size).to eq(1)
        expect(parser.present_weather[0].phenomenon).to eq('not observed')
      end
    end

    it 'present_weather_defaults_to_empty_array' do
      parser = setup_parser(
        "PAIL 061610Z 24006KT 1 3/4SM BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000"
      )
      expect(parser.present_weather.size).to eq(0)
    end

    context '.sky_conditions' do
      it 'normal' do
        parser = setup_parser(
          "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
            "RMK AO2 P0000"
        )

        expect(parser.sky_conditions.size).to eq(2)
        expect(parser.sky_conditions[0].quantity).to eq('broken')
        expect(parser.sky_conditions[0].height.value).to eq(487.68)
        expect(parser.sky_conditions[1].quantity).to eq('overcast')
        expect(parser.sky_conditions[1].height.value).to eq(914.40)
      end

      it 'auto + ///' do
        parser = setup_parser(
          "PAIL 061610Z AUTO 24006KT 1 3/4SM /// M17/M20 A2910 RMK AO2 P0000"
        )

        expect(parser.sky_conditions.size).to eq(0)
      end
    end

    it 'sky_conditions_defaults_to_empty_array' do
      parser = setup_parser(
        "PAIL 061610Z 24006KT 1 3/4SM -SN M17/M20 A2910 RMK AO2 P0000"
      )
      expect(parser.sky_conditions.size).to eq(0)
    end

    it 'vertical_visibility' do
      parser = setup_parser(
        "CYXS 151034Z AUTO 09003KT 1/8SM FZFG VV001 M03/M03 A3019 " \
          "RMK SLP263 ICG"
      )
      expect(parser.vertical_visibility.value).to eq(30.48)
    end

    it 'temperature' do
      parser = setup_parser(
        "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
          "RMK AO2 P0000"
      )
      expect(parser.temperature.value).to eq(-17)
    end

    it "accepts a blank temperature" do
      parser = setup_parser(
        "KSMO 281655Z 18003KT 9SM SCT020 /20 A3002 RMK A02 T0200 $"
      )
      expect(parser.temperature).to eq(nil)
    end

    it 'dew_point' do
      parser = setup_parser(
        "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
          "RMK AO2 P0000"
      )
      expect(parser.dew_point.value).to eq(-20)
    end

    it "accepts a blank dew_point" do
      parser = setup_parser(
        "KSMO 281655Z 18003KT 9SM SCT020 20/ A3002 RMK A02 T0200 $"
      )
      expect(parser.dew_point).to eq(nil)
    end

    it 'sea_level_pressure' do
      parser = setup_parser(
        "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
          "RMK AO2 P0000"
      )
      expect(parser.sea_level_pressure.pressure.to_inches_of_mercury).
        to eq(29.10)
    end

    it 'recent weather' do
      parser = setup_parser(
        "CYQH 310110Z 00000KT 20SM SCT035CB BKN050 RETS RMK CB4SC1"
      )

      expect(parser.recent_weather).to be_a Array
      expect(parser.recent_weather.size).to eq(1)
      expect(parser.recent_weather[0].phenomenon).to eq('thunderstorm')
    end

    context 'remarks' do
      it 'are collected' do
        parser = setup_parser(
          "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
            "RMK AO2 P0000"
        )

        expect(parser.remarks).to be_a Array
        expect(parser.remarks.size).to eq(2)
      end

      it 'remarks defaults to empty array' do
        parser = setup_parser(
          "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910"
        )

        expect(parser.remarks).to be_a Array
        expect(parser.remarks.size).to eq(0)
      end

      context 'known remarks' do
        it 'parses sea level pressure' do
          parser = setup_parser(
            'CYZT 052200Z 31010KT 20SM SKC 17/12 A3005 RMK SLP174 20046'
          )

          expect(parser.remarks[0]).to be_a(Metar::Data::SeaLevelPressure)
        end

        it 'parses extreme temperature' do
          parser = setup_parser(
            'CYZT 052200Z 31010KT 20SM SKC 17/12 A3005 RMK SLP174 20046'
          )

          expect(parser.remarks[1]).to be_temperature_extreme(:minimum, 4.6)
        end

        it 'parses density altitude' do
          parser = setup_parser(
            "CYBW 010000Z AUTO VRB04KT 9SM SCT070 13/M01 A3028 " \
              "RMK DENSITY ALT 4100FT="
          )

          expect(parser.remarks[0]).to be_a(Metar::Data::DensityAltitude)
          expect(parser.remarks[0].height.value).to be_within(0.001).of(1249.68)
        end
      end

      context 'in strict mode' do
        before do
          Metar::Parser.compliance = :strict
        end

        it 'unparsed data causes an error' do
          expect do
            setup_parser(
              "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
                "FOO RMK AO2 P0000"
            )
          end.to raise_error(Metar::ParseError, /Unparsable text found/)
        end
      end

      context 'in loose mode' do
        it 'unparsed data is collected' do
          parser = setup_parser(
            "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 " \
              "FOO RMK AO2 P0000"
          )

          expect(parser.unparsed).to eq(['FOO'])
          expect(parser.remarks.size).to eq(2)
        end
      end
    end

    context "final '='" do
      let(:parser) do
        setup_parser('LPPT 070530Z 34003KT 310V010 CAVOK 14/12 Q1013=')
      end

      it 'parses the final chunk' do
        expect(parser.sea_level_pressure.value).to eq(1.013)
      end

      context 'in strict mode' do
        before do
          Metar::Parser.compliance = :strict
        end

        it 'causes and error' do
          expect do
            parser
          end.to raise_error(Metar::ParseError, /Unparsable text found/)
        end
      end
    end

    context "final ' ='" do
      let(:parser) do
        setup_parser('LPPT 070530Z 34003KT 310V010 CAVOK 14/12 Q1013 =')
      end

      it 'parses the final chunk' do
        expect(parser.sea_level_pressure.value).to eq(1.013)
      end

      context 'in strict mode' do
        before do
          Metar::Parser.compliance = :strict
        end

        it 'causes and error' do
          expect do
            parser
          end.to raise_error(Metar::ParseError, /Unparsable text found/)
        end
      end
    end
  end

  context "#raw_attributes" do
    let(:parts) { [station_code, datetime] }
    let(:metar) { parts.join(" ") }
    let(:station_code) { "PAIL" }
    let(:datetime) { "061610Z" }
    let(:observer) { "COR" }
    let(:wind) { "24006KT" }
    let(:variable_wind) { "350V050" }
    let(:visibility) { "1 3/4SM" }
    let(:minimum_visibility) { "3/4SM" }
    let(:runway_visible_range) { "R12/1000N R30/1500N" }
    let(:present_weather) { "-SN" }
    let(:sky_conditions) { "BKN016 OVC030" }
    let(:vertical_visibility) { "VV001" }
    let(:temperature_and_dew_point) { "33/22" }
    let(:sea_level_pressure) { "A2910" }
    let(:recent_weather) { "RETS" }
    let(:remarks) { "RMK AO2 P0000" }
    let(:result) { subject.raw_attributes }

    subject { setup_parser(metar) }

    it "returns a Hash" do
      expect(subject.raw_attributes).to be_a(Hash)
    end

    [
      [:metar, "is the raw METAR string"],
      [:station_code, "the station code"],
      [:datetime, "the date/time string"]
    ].each do |attr, description|
      context attr.to_s do
        specify ":#{attr} is #{description}" do
          expect(result).to include(attr)
          expect(result[attr]).to eq(send(attr))
        end
      end
    end

    [
      [:observer, "an observer"],
      [:wind, "wind"],
      [:variable_wind, "variable wind"],
      [:visibility, "visibility"],
      [:runway_visible_range, "runway visible range"],
      [:present_weather, "present weather"],
      [:sky_conditions, "sky conditions"],
      [:vertical_visibility, "vertical visibility"],
      [:temperature_and_dew_point, "temperature and dew point"],
      [:sea_level_pressure, "sea-level pressure"],
      [:recent_weather, "recent weather"]
    ].each do |attr, name|
      context "with #{name}" do
        let(:parts) { super() + [send(attr)] }

        specify ":#{attr} is set" do
          expect(result).to include(attr)
          expect(result[attr]).to eq(send(attr))
        end
      end
    end

    context "with wind and minimum visibility" do
      let(:parts) { super() + [visibility, minimum_visibility] }

      specify ":minimum_visibility is set" do
        expect(result).to include(:minimum_visibility)
        expect(result[:minimum_visibility]).to eq(minimum_visibility)
      end
    end

    context "with CAVOK" do
      let(:parts) { super() + ["CAVOK"] }

      specify ":cavok is set" do
        expect(result).to include(:cavok)
        expect(result[:cavok]).to eq("CAVOK")
      end

      %i(
        visibility
        minimum_visibility
        runway_visible_range
        present_weather
        sky_conditions
      ).each do |attr|
        specify "#{attr} is not set" do
          expect(result).to_not include(attr)
        end
      end
    end
  end

  def setup_parser(metar)
    raw = Metar::Raw::Data.new(metar, Time.now)
    Metar::Parser.new(raw)
  end
end
