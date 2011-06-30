require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/clean'

$:.unshift(File.dirname(__FILE__) + '/lib')
require 'metar'

RDOC_OPTS = ['--quiet', '--title', 'METAR Weather Report Parser', '--main', 'README.rdoc', '--inline-source']
RDOC_PATH = 'doc/rdoc'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*.rb']
  t.verbose = true
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = RDOC_PATH
  rdoc.options += RDOC_OPTS
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.add ['README.rdoc', 'COPYING', 'lib/**/*.rb']
end

desc "Build the gem"
task :build do
  system "gem build metar-parser.gemspec"
end

desc "Publish a new version of the gem"
task :release => :build do
  system "gem push metar-parser-#{Metar::VERSION::STRING}"
end
