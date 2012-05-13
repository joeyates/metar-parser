load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

RSpec::Matchers.define :be_weather_phenomenon do | modifier, descriptor, phenomenon  |
  match do | wp |
    if wp.nil? && phenomenon.nil?
      true
    elsif wp.nil?       != phenomenon.nil?
      false
    elsif wp.phenomenon != phenomenon
      false
    elsif wp.modifier   != modifier
      false
    elsif wp.descriptor != descriptor
      false
    else
      true
    end
  end
end

describe Metar::WeatherPhenomenon do

  context '.parse' do

    [
      [ 'simple phenomenon',                  'BR',     [ nil,      nil,            'mist' ] ],
      [ 'descriptor + phenomenon',            'BCFG',   [ nil,      'patches of',   'fog'  ] ],
      [ 'modifier + phenomenon',              '+RA',    [ 'heavy',  nil,            'rain' ] ],
      [ 'modifier + descriptor + phenomenon', 'VCDRFG', [ 'nearby', 'low drifting', 'fog'  ] ],
      [ 'returns nil for unmatched',          'FUBAR',  [ nil,      nil,            nil  ] ],
    ].each do | docstring, raw, expected |
      example docstring do
        Metar::WeatherPhenomenon.parse( raw ).should be_weather_phenomenon( *expected )
      end
    end

  end

end

