# frozen_string_literal: true

require "spec_helper"

describe Metar::Data::Remark do
  context '.parse' do
    it 'delegate to subclasses' do
      expect(described_class.parse('21012')).
        to be_a(Metar::Data::TemperatureExtreme)
    end

    it 'returns nil for unrecognised' do
      expect(described_class.parse('FOO')).to be_nil
    end

    context '6-hour maximum or minimum' do
      [
        ['positive maximum', '10046', [:maximum, 4.6]],
        ['negative maximum', '11012', [:maximum, -1.2]],
        ['positive minimum', '20046', [:minimum, 4.6]],
        ['negative minimum', '21012', [:minimum, -1.2]]
      ].each do |docstring, raw, expected|
        example docstring do
          expect(described_class.parse(raw)).
            to be_temperature_extreme(*expected)
        end
      end
    end

    context '24-hour maximum and minimum' do
      it 'returns minimum and maximum' do
        max, min = described_class.parse('400461006')

        expect(max).to be_temperature_extreme(:maximum, 4.6)
        expect(min).to be_temperature_extreme(:minimum, -0.6)
      end
    end

    context 'pressure tendency' do
      it 'steady_then_decreasing' do
        pt = described_class.parse('58033')

        expect(pt).to be_a(Metar::Data::PressureTendency)
        expect(pt.character).to eq(:steady_then_decreasing)
        expect(pt.value).to eq(3.3)
      end
    end

    context '3-hour and 6-hour precipitation' do
      it '60009' do
        pr = described_class.parse('60009')

        expect(pr).to be_a(Metar::Data::Precipitation)
        expect(pr.period).to eq(3)
        expect(pr.amount.value).to eq(0.002286)
      end
    end

    context '24-hour precipitation' do
      it '70015' do
        pr = described_class.parse('70015')

        expect(pr).to be_a(Metar::Data::Precipitation)
        expect(pr.period).to eq(24)
        expect(pr.amount.value).to eq(0.003810)
      end
    end

    context 'automated station' do
      [
        [
          'with precipitation dicriminator',
          'AO1',
          [
            Metar::Data::AutomatedStationType,
            :with_precipitation_discriminator
          ]
        ],
        [
          'without precipitation dicriminator',
          'AO2',
          [
            Metar::Data::AutomatedStationType,
            :without_precipitation_discriminator
          ]
        ]
      ].each do |docstring, raw, expected|
        example docstring do
          aut = described_class.parse(raw)

          expect(aut).to be_a(expected[0])
          expect(aut.type).to eq(expected[1])
        end
      end
    end

    context 'sea-level pressure' do
      it 'SLP125' do
        slp = described_class.parse('SLP125')

        expect(slp).to be_a(Metar::Data::SeaLevelPressure)
        expect(slp.pressure.value).to eq(0.0125)
      end
    end

    context 'hourly temperature and dew point' do
      it 'T00640036' do
        htm = described_class.parse('T00641036')

        expect(htm).to be_a(Metar::Data::HourlyTemperatureAndDewPoint)
        expect(htm.temperature.value).to eq(6.4)
        expect(htm.dew_point.value).to eq(-3.6)
      end
    end
  end
end
