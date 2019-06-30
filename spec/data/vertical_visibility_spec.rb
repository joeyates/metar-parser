# frozen_string_literal: true

require "spec_helper"

RSpec::Matchers.define :be_distance do |expected|
  match do |distance|
    if    distance.nil? && expected == :expect_nil
      true
    elsif distance.nil? && expected != :expect_nil
      false
    elsif distance.value.nil? && expected.nil?
      true
    else
      (distance.value - expected).abs <= 0.01
    end
  end
end

describe Metar::Data::VerticalVisibility do
  context '.parse' do
    [
      ['VV + nnn',                  'VV300',  9144],
      ['///',                       '///',    nil],
      ['returns nil for unmatched', 'FUBAR',  :expect_nil]
    ].each do |docstring, raw, expected|
      example docstring do
        expect(described_class.parse(raw)).to be_distance(expected)
      end
    end
  end
end
