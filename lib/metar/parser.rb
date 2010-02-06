require 'rubygems' if RUBY_VERSION < '1.9'
require 'dhaka'
# require 'dhaka/runtime' switch to this when the grammar has stablized
require File.dirname(__FILE__) + '/grammar'

if not defined?(Metar::Parser)
  parser = Dhaka::Parser.new(Metar::Grammar)
  eval(parser.compile_to_ruby_source_as('Metar::Parser'.intern))
end

module Metar
  class Parser
    def save_dot(filename)
      File.open(filename, 'w') {|fil| fil.write evaluator.parser.to_dot }
    end
  end
end
