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

  s.add_dependency 'rake', '>= 0.8.7'
  s.add_dependency 'i18n', '>= 0.3.5'
  s.add_dependency 'aasm', '>= 2.1.5'
  s.add_dependency 'm9t',  '~> 0.2.1'

  s.rubyforge_project = 'nowarning'
end
