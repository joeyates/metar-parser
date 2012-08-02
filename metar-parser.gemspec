# -*- encoding: utf-8 -*-
$:.unshift( File.join( File.dirname( __FILE__ ), 'lib' ) )
require 'metar/version'
require 'rake/file_list'

Gem::Specification.new do |s|
  s.name          = 'metar-parser'
  s.summary       = 'A Ruby gem for worldwide weather reports'
  s.description   = <<-EOT
    metar-parser is a ruby gem that downloads weather reports, parses them and formats reports.

    It also provides weather station listings and info (e.g. country, latitude and longitude).

    Reports can be fully localized (currently English and Italian are available).
    EOT
  s.version       = Metar::VERSION::STRING

  s.homepage      = 'http://github.com/joeyates/metar-parser'
  s.author        = 'Joe Yates'
  s.email         = 'joe.g.yates@gmail.com'

  s.files         = ['README.md', 'COPYING', 'Rakefile'] +
                    Rake::FileList['{bin,lib,spec}/**/*.rb'] +
                    Rake::FileList['locales/**/*.{rb,yml}']
  s.require_paths = ['lib']

  s.test_files    = Rake::FileList[ 'spec/**/*_spec.rb' ]

  s.add_runtime_dependency 'rake'
  s.add_runtime_dependency 'rdoc'
  s.add_runtime_dependency 'i18n', '>= 0.3.5'
  s.add_runtime_dependency 'm9t',  '~> 0.3.1'

  s.add_development_dependency 'rspec',  '>= 2.3.0'
  if RUBY_VERSION < '1.9'
    s.add_development_dependency 'rcov'
  else
    s.add_development_dependency 'simplecov'
  end
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-doc'

  s.rubyforge_project = 'nowarning'
end

