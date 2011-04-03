# -*- encoding: utf-8 -*-
$:.unshift( File.dirname(__FILE__) + '/lib' )
require 'metar/version'
require 'rake'

spec = Gem::Specification.new do |s|
  s.name        = 'metar-parser'
  s.summary     = 'A Ruby library for METAR weather reports'
  s.description = 'A Ruby library which handle METAR weather reports. Provides weather station listings and info. Downloads and parses reports. Presents localized full text reports'
  s.version     = Metar::VERSION::STRING

  s.homepage = 'http://github.com/joeyates/metar-parser'
  s.author   = 'Joe Yates'
  s.email    = 'joe.g.yates@gmail.com'

  s.files         = ['README.rdoc', 'COPYING', 'Rakefile'] + FileList['{bin,lib,test}/**/*.rb'] + FileList['locales/**/*.{rb,yml}']
  s.require_paths = ['lib']

  s.test_file = 'test/all_tests.rb'

  s.rubyforge_project = 'nowarning'
end
