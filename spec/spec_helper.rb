# frozen_string_literal: true

require 'rspec'

if RUBY_VERSION > '1.9'
  require 'simplecov'
  if ENV['COVERAGE']
    SimpleCov.start do
      add_filter "/spec/"
    end
  end
end

require File.expand_path(File.dirname(__FILE__) + '/../lib/metar')

RSpec::Matchers.define :be_temperature_extreme do |extreme, value|
  match do |remark|
    if !remark.is_a?(Metar::Data::TemperatureExtreme)
      false
    elsif remark.extreme != extreme
      false
    else
      remark.value == value
    end
  end
end
