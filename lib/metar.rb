require 'rubygems' if RUBY_VERSION < '1.9'
require 'aasm'
require File.join(File.dirname(__FILE__), 'metar', 'raw')
require File.join(File.dirname(__FILE__), 'metar', 'station')
require File.join(File.dirname(__FILE__), 'metar', 'parser')
