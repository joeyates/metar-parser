#!/usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9'
require File.join(File.expand_path(File.dirname(__FILE__) + '/../lib'), 'metar')

Metar::Station.download_local
