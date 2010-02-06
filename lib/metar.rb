require 'rubygems' if RUBY_VERSION < '1.9'
require 'dhaka'
require File.join(File.dirname(__FILE__), 'metar', 'raw')
require File.join(File.dirname(__FILE__), 'metar', 'lexer')
require File.join(File.dirname(__FILE__), 'metar', 'parser')
require File.join(File.dirname(__FILE__), 'metar', 'evaluator')
require File.join(File.dirname(__FILE__), 'metar', 'station')
require File.join(File.dirname(__FILE__), 'metar', 'report')
