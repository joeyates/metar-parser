# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

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
      [ 'intensity + phenomenon',             '+RA',    [ 'heavy',  nil,            'rain' ] ],
      [ 'intensity + proximity + phenomenon', '-VCTSRA', [ 'nearby light', 'thunderstorm and', 'rain' ] ],
      [ '2 phenomena: SN RA',                 'SNRA',   [ nil,      nil,            'snow and rain' ] ],
      [ '2 phenomena: RA DZ',                 'RADZ',   [ nil,      nil,            'rain and drizzle' ] ],
      [ 'modifier + descriptor + phenomenon', 'VCDRFG', [ 'nearby', 'low drifting', 'fog'  ] ],
      [ 'returns nil for unmatched',          'FUBAR',  [ nil,      nil,            nil  ] ],
    ].each do | docstring, raw, expected |
      example docstring do
        Metar::WeatherPhenomenon.parse( raw ).should be_weather_phenomenon( *expected )
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
      [ 'simple phenomenon', :en, [ nil, nil, 'mist' ], 'mist' ],
      [ 'simple phenomenon', :it, [ nil, nil, 'mist' ], 'foschia' ],
      [ 'descriptor + phenomenon', :en, [ nil, 'patches of', 'fog' ], 'patches of fog' ],
      [ 'modifier + phenomenon', :en, ['heavy', nil, 'drizzle' ], 'heavy drizzle' ],
      [ 'modifier + descriptor + phenomenon', :en, ['heavy', 'freezing', 'drizzle' ], 'heavy freezing drizzle' ],
    ].each do | docstring, locale, ( modifier, descriptor, phenomenon ), expected |
      example docstring + " (#{locale})" do
        I18n.locale = locale
        Metar::WeatherPhenomenon.new( phenomenon, modifier, descriptor ).to_s.
                                  should     == expected
      end
    end

  end

end

