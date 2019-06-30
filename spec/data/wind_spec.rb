# frozen_string_literal: true

require "spec_helper"

RSpec::Matchers.define :be_wind do |direction, speed, gusts|
  match do |wind|
    if wind.nil? && [direction, speed, gusts].all?(&:nil?)
      true
    elsif wind.nil?
      false
    elsif wind.direction.nil? != direction.nil?
      false
    elsif wind.speed.nil? != speed.nil?
      false
    elsif wind.gusts.nil? != gusts.nil?
      false
    elsif direction.is_a?(Symbol) && wind.direction != direction
      false
    elsif direction.is_a?(M9t::Direction) &&
          (wind.direction.value - direction).abs > 0.01
      false
    elsif speed.is_a?(Symbol) && wind.speed != speed
      false
    elsif speed.is_a?(Metar::Data::Speed) &&
          (wind.speed.value - speed).abs > 0.01
      false
    elsif !wind.gusts.nil? && (wind.gusts.value - gusts).abs > 0.01
      false
    else
      true
    end
  end
end

describe Metar::Data::Wind do
  context '.parse' do
    [
      # Direction and speed
      [
        'treats 5 digits as degrees and kilometers per hour', '12345',
        [123.0, 12.50, nil]
      ],
      [
        'understands 5 digits + KMH', '12345KMH',
        [123.0, 12.50, nil]
      ],
      [
        'understands 5 digits + MPS', '12345MPS',
        [123.0, 45.00, nil]
      ],
      [
        'understands 5 digits + KT', '12345KT',
        [123.0, 23.15, nil]
      ],
      [
        'rounds 360 down to 0', '36045KT',
        [0.0,   23.15, nil]
      ],
      [
        'returns nil for directions outside 0 to 360', '88845KT',
        [nil, nil,   nil]
      ],
      # +gusts
      [
        'understands 5 digits + G + 2 digits', '12345G67',
        [123.0, 12.50, 18.61]
      ],
      [
        'understands 5 digits + G + 2 digits + KMH', '12345G67KMH',
        [123.0, 12.50, 18.61]
      ],
      [
        'understands 5 digits + G + 2 digits + MPS', '12345G67MPS',
        [123.0, 45.00, 67.00]
      ],
      [
        'understands 5 digits + G + 2 digits + KT', '12345G67KT',
        [123.0, 23.15, 34.47]
      ],
      # Variable direction
      [
        'understands VRB + 2 digits', 'VRB12',
        [:variable_direction, 3.33, nil]
      ],
      [
        'understands VRB + 2 digits + KMH', 'VRB12KMH',
        [:variable_direction, 3.33, nil]
      ],
      [
        'understands VRB + 2 digits + MPS', 'VRB12MPS',
        [:variable_direction, 12.00, nil]
      ],
      [
        'understands VRB + 2 digits + KT', 'VRB12KT',
        [:variable_direction, 6.17, nil]
      ],
      # + gusts
      [
        'understands VRB + 2 digits + G + 2 digits', 'VRB45G67',
        [:variable_direction, 12.50, 18.61]
      ],
      [
        'understands VRB + 2 digits + G + 2 digits + KMH', 'VRB45G67KMH',
        [:variable_direction, 12.50, 18.61]
      ],
      [
        'understands VRB + 2 digits + G + 2 digits + MPS', 'VRB45G67MPS',
        [:variable_direction, 45.00, 67.00]
      ],
      [
        'understands VRB + 2 digits + G + 2 digits + KT', 'VRB45G67KT',
        [:variable_direction, 23.15, 34.47]
      ],
      # Unknown direction
      [
        'understands /// + 2 digits', '///12',
        [:unknown_direction, 3.33, nil]
      ],
      [
        'understands /// + 2 digits + KMH', '///12KMH',
        [:unknown_direction, 3.33, nil]
      ],
      [
        'understands /// + 2 digits + MPS', '///12MPS',
        [:unknown_direction, 12.00, nil]
      ],
      [
        'understands /// + 2 digits + KT', '///12KT',
        [:unknown_direction, 6.17, nil]
      ],
      # Unknown direction and speed
      [
        'understands /////', '/////',
        [:unknown_direction, :unknown_speed, nil]
      ],
      # Bad data
      [
        'returns nil for badly formatted values', 'XYZ12KT',
        [nil, nil, nil]
      ],
      [
        'returns nil for nil', nil,
        [nil, nil, nil]
      ]
    ].each do |docstring, raw, expected|
      example docstring do
        expect(described_class.parse(raw)).to be_wind(*expected)
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
        'formats speed and direction',
        :en, [nil,                 nil, nil],
        '443km/h ESE'
      ],
      [
        'handles variable_direction',
        :en, [:variable_direction, nil, nil],
        '443km/h variable direction'
      ],
      [
        'handles unknown_direction',
        :en, [:unknown_direction, nil, nil],
        '443km/h unknown direction'
      ],
      [
        'handles unknown_speed',
        :en, [nil, :unknown_speed, nil],
        'unknown speed ESE'
      ],
      [
        'includes gusts',
        :en, [nil, nil, Metar::Data::Speed.new(123)],
        '443km/h ESE gusts 443km/h'
      ],
      [
        'formats speed and direction',
        :it, [nil,                 nil, nil],
        '443km/h ESE'
      ],
      [
        'handles variable_direction',
        :it, [:variable_direction, nil, nil],
        '443km/h direzione variabile'
      ],
      [
        'handles unknown_direction',
        :it, [:unknown_direction, nil, nil],
        '443km/h direzione sconosciuta'
      ],
      [
        'handles unknown_speed',
        :it, [nil, :unknown_speed, nil],
        'velocità sconosciuta ESE'
      ],
      [
        'includes gusts',
        :it, [nil, nil, Metar::Data::Speed.new(123)],
        '443km/h ESE folate di 443km/h'
      ]
    ].each do |docstring, locale, (direction, speed, gusts), expected|
      direction ||= M9t::Direction.new(123)
      speed     ||= Metar::Data::Speed.new(123)

      example docstring + " (#{locale})" do
        I18n.locale = locale
        subject = described_class.new(
          "chunk", direction: direction, speed: speed, gusts: gusts
        )
        expect(subject.to_s).to eq(expected)
      end
    end
  end
end
