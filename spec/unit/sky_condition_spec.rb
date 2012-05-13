load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

RSpec::Matchers.define :be_sky_condition do | quantity, height, type |
  match do | sk |
    if    sk.nil? && quantity == :expect_nil
      true
    elsif sk.nil? && quantity != :expect_nil
      false
    elsif sk.quantity != quantity
      false
    elsif sk.height.is_a?(Metar::Distance) && sk.height.value != height
      false
    elsif sk.type != type
      false
    else
      true
    end
  end
end

describe Metar::SkyCondition do

  context '.parse' do
    [
      [ 'understands clear skies codes', 'NSC',      [nil,          nil, nil            ] ],
      [ 'quantity + height',             'BKN12',    ['broken',     360, nil            ] ],
      [ 'quantity + height + condition', 'BKN12CB',  ['broken',     360, 'cumulonimbus' ] ],
      [ 'quantity + height + ///',       'BKN12///', ['broken',     360, nil            ] ],
      [ 'returns nil for unmatched',     'FUBAR',    [ :expect_nil, nil, nil            ] ],
    ].each do | docstring, raw, expected |
      example docstring do
        Metar::SkyCondition.parse( raw ).should be_sky_condition( *expected )
      end
    end

  end

end

