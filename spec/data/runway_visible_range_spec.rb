# frozen_string_literal: true

require "spec_helper"

RSpec::Matchers.define :be_runway_visible_range do |designator, v1, v2, tend|
  match do |rvr|
    if rvr.nil? && designator.nil?
      true
    elsif rvr.nil? != designator.nil?
      false
    elsif rvr.visibility1.nil? != v1.nil?
      false
    elsif rvr.visibility2.nil? != v2.nil?
      false
    elsif rvr.tendency.nil? != tend.nil?
      false
    elsif !v1.nil? &&
          ((rvr.visibility1.distance.value - v1[0]).abs > 0.01 ||
          rvr.visibility1.comparator != v1[2])
      false
    elsif !v2.nil? &&
          ((rvr.visibility2.distance.value - v2[0]).abs > 0.02 ||
          rvr.visibility2.comparator != v2[2])
      false
    else
      tend == rvr.tendency
    end
  end
end

describe Metar::Data::RunwayVisibleRange do
  context '.parse' do
    [
      [
        'understands R + nn + / + nnnn', 'R12/3400',
        ['12', [3400.00, nil, nil], nil, nil]
      ],
      [
        'understands runway positions: RLC', 'R12L/3400',
        ['12L', [3400.00, nil, nil], nil, nil]
      ],
      [
        'understands comparators: PM', 'R12/P3400',
        ['12', [3400.00, nil, :more_than], nil, nil]
      ],
      [
        'understands tendencies: NUD', 'R12/3400U',
        ['12', [3400.00, nil, nil], nil, :improving]
      ],
      [
        'understands feet', 'R12/3400FT',
        ['12', [1036.32, nil, nil], nil, nil]
      ],
      [
        'understands second visibilities (m)', 'R26/0750V1200U',
        ['12', [750.0, nil, nil], [1200.0, nil, nil], :improving]
      ],
      [
        'understands second visibilities (ft)', 'R12/1800V3400FT',
        ['12', [548.64, nil, nil], [1036.32, nil, nil], nil]
      ],
      [
        'understands second RVR (ft) w/ tendency', 'R29/1800V3400FT/U',
        ['29', [548.64, nil, nil], [1036.32, nil, nil], :improving]
      ],
      [
        'returns nil for nil', nil,
        [nil, nil, nil, nil]
      ]
    ].each do |title, raw, expected|
      example title do
        expect(described_class.parse(raw)).to be_runway_visible_range(*expected)
      end
    end
  end

  context '#to_s' do
    before :all do
      @locale = I18n.locale
      I18n.locale = :it
    end

    after :all do
      I18n.locale = @locale
    end

    [
      [
        'v1',
        :en, [[3400.00, nil, nil], nil, nil],
        'runway 14: 3400m'
      ],
      [
        'v1 and v2',
        :en, [[3400.00, nil, nil], [1900.00, nil, nil], nil],
        'runway 14: from 3400m to 1900m'
      ],
      [
        'v1 and tendency',
        :en, [[3400.00, nil, nil], nil, :improving],
        'runway 14: 3400m improving'
      ]
    ].each do |title, locale, (visibility1, visibility2, tendency), expected|
      d1 = Metar::Data::Distance.new(visibility1[0])
      v1 = Metar::Data::Visibility.new(
        nil, distance: d1, direction: visibility1[1], comparator: visibility1[2]
      )
      v2 =
        if !visibility2.nil?
          d2 = Metar::Data::Distance.new(visibility2[0])
          Metar::Data::Visibility.new(
            nil,
            distance: d2, direction: visibility2[1], comparator: visibility2[2]
          )
        end

      example title + " (#{locale})" do
        I18n.locale = locale
        subject = described_class.new(
          nil,
          designator: '14',
          visibility1: v1, visibility2: v2, tendency: tendency
        )
        expect(subject.to_s).to eq(expected)
      end
    end
  end
end
