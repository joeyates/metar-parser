require 'rubygems' if RUBY_VERSION < '1.9'
require 'rubygems/package_task'
require 'rdoc/task'
require 'rake/testtask'
require 'rake/clean'
require 'rcov/rcovtask' if RUBY_VERSION < '1.9'

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

Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.rcov_opts  = [ "--exclude '/gems/'" ]
end

if RUBY_VERSION < '1.9'
  Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = RDOC_PATH
    rdoc.options += RDOC_OPTS
    rdoc.main = 'README.rdoc'
    rdoc.rdoc_files.add ['README.rdoc', 'COPYING', 'lib/**/*.rb']
  end
end

desc "Build the gem"
task :build do
  `gem build metar-parser.gemspec`
end

desc "Publish a new version of the gem"
task :release => :build do
  `gem push metar-parser-#{Metar::VERSION::STRING}.gem`
end

