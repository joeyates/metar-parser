# frozen_string_literal: true

require "spec_helper"

describe Metar::Data::Pressure do
  context '.parse' do
    it 'interprets the Q prefix as hectopascals' do
      expect(described_class.parse('Q1300').value).to be_within(0.01).of(1.3)
    end

    it 'interprets the A prefix as inches of mercury' do
      expect(described_class.parse('A1234').value).to be_within(0.01).of(0.42)
    end

    it 'require 4 digits' do
      expect(described_class.parse('Q12345')).to be_nil
      expect(described_class.parse('A123')).to be_nil
    end

    it 'returns nil for nil' do
      expect(described_class.parse(nil)).to be_nil
    end
  end
end
