# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

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
      [ 'understands clear skies codes', 'NSC',      [ nil,            nil,            nil ] ],
      [ 'quantity + height',             'BKN12',    [ 'broken',    365.76,            nil ] ],
      [ 'quantity + height + type',      'BKN12CB',  [ 'broken',    365.76, 'cumulonimbus' ] ],
      [ 'quantity + ///',                'BKN///',   [ 'broken',       nil,            nil ] ],
      [ 'quantity + height + ///',       'FEW038///',[ 'few',      1158.24,            nil ] ],
      [ 'cumulonimbus only',             'CB',       [ nil,            nil, 'cumulonimbus' ] ], # seems non-standard, but occurs
      [ 'returns nil for unmatched',     'FUBAR',    [ :expect_nil,    nil,            nil ] ],
    ].each do | docstring, raw, expected |
      example docstring do
        Metar::SkyCondition.parse( raw ).should be_sky_condition( *expected )
      end
    end

  end

  context '.to_summary' do

    [
      [ 'all values nil',  [ nil,      nil, nil ],           'clear skies'         ],
      [ 'quantity',        [ 'broken', nil, nil ],           'broken cloud'        ],
      [ 'quantity + type', [ 'broken', nil, 'cumulonimbus'], 'broken cumulonimbus' ],
    ].each do | docstring, ( quantity, height, type ), expected |
      example docstring do
        sk = Metar::SkyCondition.new( quantity, height, type )
      
        sk.to_summary.            should     == expected
      end
    end

  end

  context '.to_s' do

    [
      [ 'all values nil',  [ nil,      nil, nil ],           'clear skies'                ],
      [ 'quantity',        [ 'broken', 360, nil ],           'broken cloud at 360'        ],
      [ 'quantity + type', [ 'broken', 360, 'cumulonimbus'], 'broken cumulonimbus at 360' ],
    ].each do | docstring, ( quantity, height, type ), expected |
      example docstring do
        sk = Metar::SkyCondition.new( quantity, height, type )
      
        sk.to_s.                  should     == expected
      end
    end

  end

end

