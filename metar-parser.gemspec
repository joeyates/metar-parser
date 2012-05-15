# -*- encoding: utf-8 -*-
$:.unshift( File.join( File.dirname( __FILE__ ), 'lib' ) )
require 'metar/version'
require 'rake/file_list'

Gem::Specification.new do |s|
  s.name          = 'metar-parser'
  s.summary       = 'A Ruby library for METAR weather reports'
  s.description   = 'A Ruby library which handle METAR weather reports. Provides weather station listings and info. Downloads and parses reports. Presents localized full text reports'
  s.version       = Metar::VERSION::STRING

  s.homepage      = 'http://github.com/joeyates/metar-parser'
  s.author        = 'Joe Yates'
  s.email         = 'joe.g.yates@gmail.com'

  s.files         = ['README.md', 'COPYING', 'Rakefile'] +
                    Rake::FileList['{bin,lib,spec}/**/*.rb'] +
                    Rake::FileList['locales/**/*.{rb,yml}']
  s.require_paths = ['lib']

  s.test_files    = Rake::FileList[ 'spec/**/*_spec.rb' ]

  s.add_runtime_dependency 'rake', '>= 0.8.7'
  s.add_runtime_dependency 'rdoc'
  s.add_runtime_dependency 'i18n', '>= 0.3.5'
  s.add_runtime_dependency 'aasm', '>= 2.1.5'
  s.add_runtime_dependency 'm9t',  '~> 0.2.3'

  s.add_development_dependency 'rspec',  '>= 2.3.0'
  if RUBY_VERSION < '1.9'
    s.add_development_dependency 'rcov'
  end

  s.rubyforge_project = 'nowarning'
end

