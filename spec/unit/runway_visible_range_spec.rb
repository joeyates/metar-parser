load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

RSpec::Matchers.define :be_runway_visible_range do | designator, visibility1, visibility2, tendency |
  match do | rvr |
    if rvr.nil?                && designator.nil?
      true
    elsif rvr.nil?             != designator.nil?
      false
    elsif rvr.visibility1.nil? != visibility1.nil?
      false
    elsif rvr.visibility2.nil? != visibility2.nil?
      false
    elsif rvr.tendency.nil? != tendency.nil?
      false
    elsif ! visibility1.nil? &&
          ( ( rvr.visibility1.distance.value - visibility1[0] ).abs > 0.01 ||
            rvr.visibility1.comparator != visibility1[ 2 ] )
      false
    elsif ! visibility2.nil? &&
          ( ( rvr.visibility2.distance.value - visibility2[0] ).abs > 0.02 ||
            rvr.visibility2.comparator != visibility2[2] )
      false
    elsif tendency != rvr.tendency
      false
    else
      true
    end
  end
end

describe Metar::RunwayVisibleRange do

  context '.parse' do

    [
      [ 'understands R + nn + / + nnnn',     'R12/3400',        [ '12',  [3400.00, nil, nil],        nil,                nil ] ],
      [ 'understands runway positions: RLC', 'R12L/3400',       [ '12L', [3400.00, nil, nil],        nil,                nil ] ],
      [ 'understands comparators: PM',       'R12/P3400',       [ '12',  [3400.00, nil, :more_than], nil,                nil ] ],
      [ 'understands tendencies: NUD',       'R12/3400U',       [ '12',  [3400.00, nil, nil],        nil,                :improving ] ],
      [ 'understands feet',                  'R12/3400FT',      [ '12',  [1036.32, nil, nil],        nil,                nil ] ],
      [ 'understands second visibilties',    'R12/3400V1800FT', [ '12',  [1036.32, nil, nil],        [548.64, nil, nil], nil ] ],
      [ 'returns nil for nil',               nil,               [ nil,   nil,                        nil,                nil ] ],
    ].each do | docstring, raw, expected |
      example docstring do
        Metar::RunwayVisibleRange.parse( raw ).should be_runway_visible_range( *expected )
      end
    end

  end

end

