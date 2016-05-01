# encoding: utf-8
require "spec_helper"

describe Metar::Temperature do
  context '.parse' do
    it 'understands numbers' do
      t = Metar::Temperature.parse('5')

      expect(t.value).to be_within(0.01).of(5.0)
    end

    it 'treats an M-prefix as a negative indicator' do
      t = Metar::Temperature.parse('M5')

      expect(t.value).to be_within(0.01).of(-5.0)
    end

    it 'returns nil for other values' do
      expect(Metar::Temperature.parse('')).to be_nil
      expect(Metar::Temperature.parse('aaa')).to be_nil
    end
  end

  context '#to_s' do
    it 'abbreviates the units' do
      t = Metar::Temperature.new(5)

      expect(t.to_s).to eq('5°C')
    end

    it 'rounds to the nearest degree' do
      expect(Metar::Temperature.new(5.1).to_s).to eq('5°C')
      expect(Metar::Temperature.new(5.5).to_s).to eq('6°C')
    end
  end
end
