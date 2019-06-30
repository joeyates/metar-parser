# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'metar/version'

Gem::Specification.new do |s|
  s.name = 'metar-parser'
  s.summary = 'A Ruby gem for worldwide weather reports'
  s.description = <<-DESCRIPTION
    metar-parser is a ruby gem that downloads weather reports, parses them and formats reports.

    It also provides weather station listings and info (e.g. country, latitude and longitude).

    Reports can be fully localized (currently Brazilian Portuguese, English, German and Italian are available).
  DESCRIPTION
  s.version = Metar::VERSION::STRING
  s.required_ruby_version = '>= 2.4.0'

  s.homepage = 'https://github.com/joeyates/metar-parser'
  s.author = 'Joe Yates'
  s.email = 'joe.g.yates@gmail.com'

  s.files =
    ['README.md', 'COPYING', 'Rakefile'] +
    Dir.glob("{bin,lib,spec}/**/*.rb") +
    Dir.glob("locales/**/*.{rb,yml}")

  s.require_paths = ['lib']

  s.test_files = Dir.glob("spec/**/*_spec.rb")

  s.add_runtime_dependency 'i18n', '~> 0.7.0'
  s.add_runtime_dependency 'm9t',  '~> 0.3.5'

  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-doc'
  s.add_development_dependency 'rake', '< 11.0'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'timecop'

  s.rubyforge_project = 'nowarning'
end
