# frozen_string_literal: true

require "spec_helper"

describe Metar::Report do
  context 'attributes' do
    let(:parser) do
      double(
        Metar::Parser,
        station_code: station_code,
        date: Date.parse(metar_date),
        time: Time.parse(metar_datetime),
        observer: :real
      )
    end
    let(:station_code) { "SSSS" }
    let(:locale) { I18n.locale }
    let(:metar_date) { "2008/05/06" }
    let(:metar_time) { "10:56" }
    let(:metar_datetime) { "#{metar_date} #{metar_time}" }
    let(:station) do
      double(Metar::Station, name: 'Airport 1', country: 'Wwwwww')
    end

    before do
      allow(Metar::Station).
        to receive(:find_by_cccc).with(station_code) { station }
    end

    subject { described_class.new(parser) }

    after :each do
      I18n.locale = locale
    end

    context '#date' do
      it 'formats the date' do
        expect(subject.date).to eq('06/05/2008')
      end
    end

    context '#time' do
      it "is equal to the METAR time" do
        expect(subject.time).to eq(metar_time)
      end

      it 'zero-pads single figure minutes' do
        allow(parser).to receive(:time) { Time.parse('10:02') }

        expect(subject.time).to eq('10:02')
      end
    end

    context '#observer' do
      it "returns the observer" do
        expect(subject.observer).to eq('real')
      end
    end

    context "#station_name" do
      it "returns the name" do
        expect(subject.station_name).to eq('Airport 1')
      end
    end

    context "#station_country" do
      it "returns the country" do
        expect(subject.station_country).to eq('Wwwwww')
      end
    end

    context "#station_code" do
      it "returns the station code" do
        expect(subject.station_code).to eq(station_code)
      end
    end

    context 'proxied from parser' do
      context 'singly' do
        %i(
          wind
          variable_wind
          visibility
          minimum_visibility
          vertical_visibility
          temperature
          dew_point
        ).each do |attribute|
          example attribute do
            allow(parser).to receive(attribute) { attribute.to_s }

            expect(subject.send(attribute)).to eq(attribute.to_s)
          end
        end

        context "sea_level_pressure" do
          let(:sea_level_pressure) do
            double(Metar::Data::SeaLevelPressure, value: "slp")
          end

          it "returns the summary" do
            allow(parser).to receive(:sea_level_pressure) { sea_level_pressure }

            expect(subject.sea_level_pressure).to eq("slp")
          end
        end

        context "#sky_summary" do
          let(:conditions1) { double(to_summary: "skies1") }

          it "returns the summary" do
            allow(parser).to receive(:sky_conditions) { [conditions1] }

            expect(subject.sky_summary).to eq("skies1")
          end

          it "clear skies when missing" do
            allow(parser).to receive(:sky_conditions) { [] }

            expect(subject.sky_summary).to eq("clear skies")
          end

          it "uses the last, if there is more than 1" do
            @skies1 = double("sky_conditions1")
            @skies2 = double("sky_conditions2", to_summary: "skies2")
            allow(parser).to receive(:sky_conditions) { [@skies1, @skies2] }

            expect(subject.sky_summary).to eq("skies2")
          end
        end
      end

      context "joined" do
        it "#runway_visible_range" do
          @rvr1 = double("rvr1", to_s: "rvr1")
          @rvr2 = double("rvr2", to_s: "rvr2")
          allow(parser).to receive(:runway_visible_range) { [@rvr1, @rvr2] }

          expect(subject.runway_visible_range).to eq("rvr1, rvr2")
        end

        it "#present_weather" do
          allow(parser).to receive(:present_weather) { %w(pw1 pw2) }

          expect(subject.present_weather).to eq("pw1, pw2")
        end

        it "#remarks" do
          allow(parser).to receive(:remarks) { %w(rem1 rem2) }

          expect(subject.remarks).to eq("rem1, rem2")
        end

        it '#sky_conditions' do
          sky1 = double('sky1', to_s: 'sky1')
          sky2 = double('sky2', to_s: 'sky2')
          allow(parser).to receive(:sky_conditions) { [sky1, sky2] }

          expect(subject.sky_conditions).to eq("sky1, sky2")
        end
      end
    end

    context '#to_s' do
      let(:sky1) { double('sky1', to_summary: 'sky1') }
      let(:sky2) { double('sky2', to_summary: 'sky2') }

      before do
        allow(parser).to receive(:wind) { "wind" }
        allow(parser).to receive(:visibility) { "visibility" }
        allow(parser).to receive(:minimum_visibility) { "min visibility" }
        allow(parser).to receive(:present_weather) { ["pw"] }
        allow(parser).to receive(:sky_conditions) { [sky1, sky2] }
        allow(parser).to receive(:temperature) { "temp" }
      end

      it "returns the full report" do
        expected = <<-EXPECTED.gsub(/^\s{10}/, "")
          name: Airport 1
          country: Wwwwww
          time: #{metar_time}
          wind: wind
          visibility: visibility
          minimum visibility: min visibility
          weather: pw
          sky: sky2
          temperature: temp
        EXPECTED
        expect(subject.to_s).to eq(expected)
      end
    end
  end
end
