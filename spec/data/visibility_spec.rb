# frozen_string_literal: true

require "spec_helper"

RSpec::Matchers.define :be_visibility do |distance, direction, comparator|
  match do |visibility|
    if visibility.nil? && [distance, direction, comparator].all?(&:nil?)
      true
    elsif visibility.nil? != [distance, direction, comparator].all?(&:nil?)
      false
    elsif visibility.distance.nil?   != distance.nil?
      false
    elsif visibility.direction.nil?  != direction.nil?
      false
    elsif visibility.comparator.nil? != comparator.nil?
      false
    elsif visibility.distance.is_a?(Metar::Data::Distance) &&
          (visibility.distance.value - distance).abs > 0.01
      false
    elsif visibility.direction.is_a?(M9t::Direction) &&
          (visibility.direction.value - direction).abs > 0.01
      false
    elsif comparator.is_a?(Symbol) && visibility.comparator != comparator
      false
    else
      true
    end
  end
end

describe Metar::Data::Visibility do
  context '.parse' do
    [
      ['understands 9999',          '9999',    [10_000.00, nil, :more_than]],
      ['understands nnnn + NDV',    '0123NDV', [123.00, nil, nil]],
      ['understands n/nSM',         '3/4SM',   [1207.01, nil,   nil]],
      ['understands 3/16SM',        '3/16SM',  [301.752, nil,   nil]],
      ['understands n n/nSM',       '1 1/4SM', [2011.68, nil,   nil]],
      ['understands nSM',           '5SM',     [8046.72, nil,   nil]],
      ['understands M1/4SM',        'M1/4SM',  [402.34, nil, :less_than]],
      ['understands n + KM',        '5KM',     [5000.00, nil, nil]],
      ['understands n',             '500',     [500.00, nil,   nil]],
      ['understands n + compass',   '500NW',   [500.00, 315.0, nil]],
      ['returns nil for unmatched', 'FUBAR',   [nil, nil, nil]]
    ].each do |docstring, raw, expected|
      example docstring do
        expect(described_class.parse(raw)).to be_visibility(*expected)
      end
    end
  end

  context '#to_s' do
    before :each do
      @locale = I18n.locale
      I18n.locale = :it
    end

    after :each do
      I18n.locale = @locale
    end

    [
      [
        'with distance',
        :en, [:set, nil, nil], '4km'
      ],
      [
        'with distance and direction',
        :en, [:set, :set, nil], '4km ESE'
      ],
      [
        'with distance and comparator',
        :en, [:set, nil, :less_than], 'less than 4km'
      ],
      [
        'with distance, direction and comparator',
        :en, %i(set set more_than), 'more than 4km ESE'
      ],
      [
        'with distance and direction',
        :it, [:set, :set, nil], '4km ESE'
      ],
      [
        'with distance, direction and comparator',
        :it, %i(set set more_than), 'piú di 4km ESE'
      ]
    ].each do |docstring, locale, (distance, direction, comparator), expected|
      distance  = Metar::Data::Distance.new(4321) if distance == :set
      direction = M9t::Direction.new(123) if direction == :set

      example docstring + " (#{locale})" do
        I18n.locale = locale
        subject = described_class.new(
          nil, distance: distance, direction: direction, comparator: comparator
        )

        expect(subject.to_s).to eq(expected)
      end
    end
  end
end
