#!/usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9'
require 'yaml'
require File.join(File.expand_path(File.dirname(__FILE__) + '/../lib'), 'metar')

filename = File.join(File.expand_path(File.dirname(__FILE__) + '/../data'), "stations.yml")
stations = YAML.load_file(filename)

stations.each_pair do |cccc, metar|
  $stderr.puts "#{ cccc }: #{ metar }"
  tokens = Metar::Lexer.lex(metar)
  parser = Metar::Parser.parse(tokens)
  if parser.class != Dhaka::ParseSuccessResult
    puts ': Parser error'
    puts metar
    puts parser.inspect
    exit
  end
  evaluator = Metar::Evaluator.new(metar)
  evaluator.run!
  report = evaluator.report
end
