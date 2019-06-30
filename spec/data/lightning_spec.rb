# frozen_string_literal: true

require "spec_helper"

describe Metar::Data::Lightning do
  context '.parse_chunks' do
    [
      [
        'direction', 'LTG SE',
        [:default, nil, ['SE']]
      ],
      [
        'distance direction', 'LTG DSNT SE',
        [:default, 16_093.44, ['SE']]
      ],
      [
        'distance direction and direction', 'LTG DSNT NE AND W',
        [:default, 16_093.44, %w(NE W)]
      ],
      [
        'distance direction-direction', 'LTG DSNT SE-SW',
        [:default, 16_093.44, %w(SE SW)]
      ],
      [
        'distance all quandrants', 'LTG DSNT ALQDS',
        [:default, 16_093.44, %w(N E S W)]
      ]
    ].each do |docstring, section, expected|
      example docstring do
        chunks = section.split(' ')
        r = described_class.parse_chunks(chunks)

        expect(r).to be_a(described_class)
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
      chunks = %w(LTG DSNT SE FOO)

      described_class.parse_chunks(chunks)

      expect(chunks).to eq(['FOO'])
    end

    it 'fails if the first chunk is not LTGnnn' do
      expect do
        described_class.parse_chunks(['FOO'])
      end.to raise_error(RuntimeError, /not lightning/)
    end

    it "doesn't not fail if all chunks are parsed" do
      chunks = %w(LTG DSNT SE)

      described_class.parse_chunks(chunks)

      expect(chunks).to eq([])
    end
  end
end
