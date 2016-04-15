require "spec_helper"

RSpec::Matchers.define :be_distance do |expected|
  match do |distance|
    if    distance.nil? && expected == :expect_nil
      true
    elsif distance.nil? && expected != :expect_nil
      false
    elsif distance.value.nil? && expected.nil?
      true
    elsif (distance.value - expected).abs > 0.01
      false
    else
      true
    end
  end
end

describe Metar::VerticalVisibility do
  context '.parse' do
    [
      ['VV + nnn',                  'VV300',  9144],
      ['///',                       '///',    nil],
      ['returns nil for unmatched', 'FUBAR',  :expect_nil],
    ].each do |docstring, raw, expected|
      example docstring do
        expect(Metar::VerticalVisibility.parse(raw)).to be_distance(expected)
      end
    end
  end
end
