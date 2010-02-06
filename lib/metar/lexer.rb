require 'rubygems' if RUBY_VERSION < '1.9'
require 'dhaka'
# require 'dhaka/runtime' switch to this when the grammar has stablized
require File.dirname(__FILE__) + '/lexer_specification'

if not defined?(Metar::Lexer)
  lexer = Dhaka::Lexer.new(Metar::LexerSpecification)
  eval(lexer.compile_to_ruby_source_as('Metar::Lexer'.intern))
end
