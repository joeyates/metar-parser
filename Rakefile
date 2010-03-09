require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/clean'

$:.unshift(File.dirname(__FILE__) + '/lib')
require 'metar'

RDOC_OPTS = ['--quiet', '--title', 'METAR Weather Report Parser', '--main', 'README.rdoc', '--inline-source']
CLEAN.include 'doc'

task :default => :test

spec = Gem::Specification.new do |s|
  s.name = 'metar-parser'
  s.description = 'Downloads, parses and presents METAR weather reports'
  s.summary = 'Downloads and parses weather reports'
  s.version = Metar::VERSION::STRING

  s.homepage = 'http://github.com/joeyates/metar-parser'
  s.author = 'Joe Yates'
  s.email = 'joe.g.yates@gmail.com'

  s.files = ['README.rdoc', 'COPYING', 'Rakefile'] + FileList['{bin,lib,test}/**/*.rb']
  s.require_paths = ['lib']
  s.add_dependency('aasm', '>= 2.1.5')
  s.add_dependency('i18n', '>= 0.3.5')

  s.has_rdoc = true
  s.rdoc_options += RDOC_OPTS
  s.extra_rdoc_files = ['README.rdoc', 'COPYING']

  s.test_file = 'test/all_tests.rb'
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/unit/*_test.rb']
  t.verbose = true
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options += RDOC_OPTS
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.add ['README.rdoc', 'COPYING', 'lib/**/*.rb']
end

Rake::GemPackageTask.new(spec) do |pkg|
end
