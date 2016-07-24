require "spec_helper"

describe Metar::Remark do
  context '.parse' do
    it 'delegate to subclasses' do
      expect(Metar::Remark.parse('21012')).to be_a(Metar::TemperatureExtreme)
    end

    it 'returns nil for unrecognised' do
      expect(Metar::Remark.parse('FOO')).to be_nil
    end

    context '6-hour maximum or minimum' do
      [
        ['positive maximum', '10046', [:maximum,  4.6]],
        ['negative maximum', '11012', [:maximum, -1.2]],
        ['positive minimum', '20046', [:minimum,  4.6]],
        ['negative minimum', '21012', [:minimum, -1.2]],
      ].each do |docstring, raw, expected|
        example docstring do
          expect(Metar::Remark.parse(raw)).to be_temperature_extreme(*expected)
        end
      end
    end

    context '24-hour maximum and minimum' do
      it 'returns minimum and maximum' do
        max, min = Metar::Remark.parse('400461006')

        expect(max).to be_temperature_extreme(:maximum,  4.6)
        expect(min).to be_temperature_extreme(:minimum, -0.6)
      end
    end

    context 'pressure tendency' do
      it 'steady_then_decreasing' do
        pt = Metar::Remark.parse('58033')

        expect(pt).to be_a(Metar::PressureTendency)
        expect(pt.character).to eq(:steady_then_decreasing)
        expect(pt.value).to eq(3.3)
      end
    end

    context '3-hour and 6-hour precipitation' do
      it '60009' do
        pr = Metar::Remark.parse('60009')

        expect(pr).to be_a(Metar::Precipitation)
        expect(pr.period).to eq(3)
        expect(pr.amount.value).to eq(0.002286)
      end
    end

    context '24-hour precipitation' do
      it '70015' do
        pr = Metar::Remark.parse('70015')

        expect(pr).to be_a(Metar::Precipitation)
        expect(pr.period).to eq(24)
        expect(pr.amount.value).to eq(0.003810)
      end
    end

    context 'automated station' do

      [
        ['with precipitation dicriminator', 'AO1', [Metar::AutomatedStationType, :with_precipitation_discriminator]],
        ['without precipitation dicriminator', 'AO2', [Metar::AutomatedStationType, :without_precipitation_discriminator]],
      ].each do |docstring, raw, expected|
        example docstring do
          aut = Metar::Remark.parse(raw)

          expect(aut).to be_a(expected[0])
          expect(aut.type).to eq(expected[1])
        end
      end
    end

    context 'sea-level pressure' do
      it 'SLP125' do
        slp = Metar::Remark.parse('SLP125')

        expect(slp).to be_a(Metar::SeaLevelPressure)
        expect(slp.pressure.value).to eq(0.0125)
      end
    end

    context 'hourly temperature and dew point' do
      it 'T00640036' do
        htm = Metar::Remark.parse('T00641036')

        expect(htm).to be_a(Metar::HourlyTemperatureAndDewPoint)
        expect(htm.temperature.value).to eq(6.4)
        expect(htm.dew_point.value).to eq(-3.6)
      end
    end
  end
end

describe Metar::Lightning do
  context '.parse_chunks' do
    [
      ['direction',                        'LTG SE',            [:default,      nil, ['SE']]],
      ['distance direction',               'LTG DSNT SE',       [:default, 16093.44, ['SE']]],
      ['distance direction and direction', 'LTG DSNT NE AND W', [:default, 16093.44, ['NE', 'W']]],
      ['distance direction-direction',     'LTG DSNT SE-SW',    [:default, 16093.44, ['SE', 'SW']]],
      ['distance all quandrants',          'LTG DSNT ALQDS',    [:default, 16093.44, ['N', 'E', 'S', 'W']]],
    ].each do |docstring, section, expected|
      example docstring do
        chunks = section.split(' ')
        r = Metar::Lightning.parse_chunks(chunks)

        expect(r).to be_a(Metar::Lightning)
        expect(r.type).to eq(expected[0])
        if expected[1]
          expect(r.distance.value).to eq(expected[1])
        else
          expect(r.distance).to be_nil
        end
        expect(r.directions).to eq(expected[2])
      end
    end

    it 'removes parsed chunks' do
      chunks = ['LTG', 'DSNT', 'SE', 'FOO']

      r = Metar::Lightning.parse_chunks(chunks)

      expect(chunks).to eq(['FOO'])
    end

    it 'fails if the first chunk is not LTGnnn' do
      expect do
        Metar::Lightning.parse_chunks(['FOO'])
      end.to raise_error(RuntimeError, /not lightning/)
    end

    it "doesn't not fail if all chunks are parsed" do
      chunks = ['LTG', 'DSNT', 'SE']

      r = Metar::Lightning.parse_chunks(chunks)

      expect(chunks).to eq([])
    end
  end
end
