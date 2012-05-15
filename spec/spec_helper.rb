require 'rspec'
require 'rspec/autorun'

if RUBY_VERSION > '1.9'
  require 'simplecov'
  if ENV[ 'COVERAGE' ]
    SimpleCov.start do
      add_filter "/spec/"
    end
  end
end

require File.expand_path( File.dirname(__FILE__) + '/../lib/metar' )

