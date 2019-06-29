# frozen_string_literal: true

require "bundler/gem_tasks"
require 'rcov/rcovtask' if RUBY_VERSION < '1.9'
require 'rspec/core/rake_task'

task default: :spec

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end
