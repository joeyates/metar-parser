# frozen_string_literal: true

require "spec_helper"

describe Metar::Data::Distance do
  let(:value) { 12_345.6789 }

  subject { described_class.new(value) }

  context '#value' do
    it 'treats the parameter as meters' do
      expect(subject.value).to eq(12_345.6789)
    end
  end

  context '#to_s' do
    it 'should default to meters' do
      expect(subject.to_s).to match(/\A\d+m\z/)
    end

    context 'when overriding the serialization_units' do
      subject do
        super().tap { |d| d.serialization_units = :miles }
      end

      it 'uses the override' do
        expect(subject.to_s).to match(/\A\d+mi\z/)
      end
    end

    context 'when <= 0.5' do
      let(:value) { 12.345678 }

      it 'should round down to the nearest meter' do
        expect(subject.to_s).to eq('12m')
      end
    end

    context 'when > 0.5' do
      let(:value) { 8.750 }

      it 'should round up to meters' do
        expect(subject.to_s).to eq('9m')
      end
    end

    it 'allows units overrides' do
      expect(subject.to_s(units: :kilometers)).to eq('12km')
    end

    it 'allows precision overrides' do
      expect(subject.to_s(precision: 1)).to eq('12345.7m')
    end

    context 'when value is nil' do
      let(:value) { nil }

      it 'is unknown' do
        expect(subject.to_s).to eq('unknown')
      end
    end

    context 'translated' do
      before do
        @locale     = I18n.locale
        I18n.locale = :it
      end

      after do
        I18n.locale = @locale
      end

      it 'localizes the decimal separator' do
        expect(subject.to_s(precision: 1)).to eq('12345,7m')
      end

      context 'when value is nil' do
        let(:value) { nil }

        it 'translates' do
          expect(subject.to_s).to eq('sconosciuto')
        end
      end
    end
  end
end
