require 'rspec'

if RUBY_VERSION > '1.9'
  require 'simplecov'
  if ENV[ 'COVERAGE' ]
    SimpleCov.start do
      add_filter "/spec/"
    end
  end
end

require File.expand_path( File.dirname(__FILE__) + '/../lib/metar' )

RSpec::Matchers.define :be_temperature_extreme do |extreme, value|
  match do |remark|
    if    not remark.is_a?(Metar::TemperatureExtreme)
      false
    elsif remark.extreme != extreme
      false
    elsif remark.value   != value
      false
    else
      true
    end
  end
end

