require 'rubygems' if RUBY_VERSION < '1.9'
require 'dhaka'

module Metar

  class LexerSpecification < Dhaka::LexerSpecification

    for_pattern('\d\d\d\d\d\dZ') do
      create_token('datetime_literal')
    end

    for_pattern('(VRB|\d\d\d)(\d\d)(G\d\d)?KT') do
      create_token('windgroup_literal')
    end

    for_pattern('AUTO') do
      create_token('auto_literal')
    end

    for_pattern('COR') do
      create_token('cor_literal')
    end

    for_pattern('\d+V\d+') do
      create_token('variable_windgroup_literal')
    end

    # TODO missing some manual values
    for_pattern('(0|M1\/4|1\/8|1\/4|1\/2|3\/4|1|1 (1\/4|1\/2|3\/4)|2|2 1\/2|3|4|5|6|7|8|9|1[0-5]|20|25|30|35)SM') do
      create_token('standard_miles_literal')
    end

    for_pattern('\d+KM') do
      create_token('kilometers_literal')
    end

    for_pattern('(VC|\+|-)?(FZ)?DZ') do
      create_token('present_weather_literal')
    end

    for_pattern('(VC|\+|-)?(SH|TS|FZ)?RA') do
      create_token('present_weather_literal')
    end

    for_pattern('(VC|\+|-)?(DR|BL|SH|TS)?SN') do
      create_token('present_weather_literal')
    end

    for_pattern('(VC|\+|-)?SG') do
      create_token('present_weather_literal')
    end

    for_pattern('IC') do
      create_token('present_weather_literal')
    end

    for_pattern('(VC|\+|-)?(SH|TS)?PL') do
      create_token('present_weather_literal')
    end

    for_pattern('(SH|TS)?GR') do
      create_token('present_weather_literal')
    end

    for_pattern('(SH|TS)?GS') do
      create_token('present_weather_literal')
    end

    for_pattern('UP') do
      create_token('present_weather_literal')
    end

    # TODO Thunderstorms, Showers, Freezing

    for_pattern('(BR|HZ)') do
      create_token('present_weather_literal')
    end

    # TODO Other obscurations

    for_pattern('VV\d+') do
      create_token('few_literal') # TODO change name
    end

    # TODO
    for_pattern('FEW\d+\w*') do
      create_token('few_literal')
    end

    # TODO
    for_pattern('OVC\d+\w*') do
      create_token('few_literal')
    end

    for_pattern('SCT\d+') do
      s = current_lexeme.characters.join
      create_token('scattered_cloud_literal')
    end

    for_pattern('BKN\d+') do
      s = current_lexeme.characters.join
      create_token('broken_cloud_literal')
    end

    for_pattern('M?\d+\/(M?\d+)?') do
      create_token('temperature_dew_point_literal')
    end

    for_pattern('A\d\d\d\d') do
      create_token('altimeter_inches_hg_literal')
    end

    for_pattern('Q\d+') do
      create_token('altimeter_hectopascals_literal')
    end

    for_pattern('NOSIG') do
      create_token('nosig_literal')
    end

    for_pattern 'RMK' do
      create_token('remark_literal')
    end

    for_pattern('SLP\d\d\d') do
      create_token('sea_level_pressure_literal')
    end

    for_pattern '\/\/\/\/\/\/' do
      create_token('six_slashes_literal')
    end

#    for_pattern '\/\/\/\/\/' do
#      create_token('five_slashes_literal')
#    end

    for_pattern '\/\/\/\/' do
      create_token('four_slashes_literal')
    end

    for_pattern '\/\/' do
      create_token('two_slashes_literal')
    end

    for_pattern '\d+' do
      create_token('numeric')
    end

    for_pattern '(\w|\d|\/)+' do
      create_token('symbol')
    end

    for_pattern ' +' do
      # Ignore whitespace
    end

    for_pattern "\n+" do
      # Ignore newlines
    end

  end

end
