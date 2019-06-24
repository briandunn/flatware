# frozen_string_literal: true

require 'bundler'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'

for gem_name in %w[flatware flatware-rspec flatware-cucumber]
  Bundler::GemHelper.install_tasks name: gem_name
end

RSpec::Core::RakeTask.new :spec do |task|
  task.pattern = FileList['spec/**/*_spec.rb']
  task.rspec_opts = %w[-f doc] if ENV['TRAVIS']
  task.verbose = false
end

Cucumber::Rake::Task.new :cucumber do |task|
  task.cucumber_opts = ['--tags', 'not @wip']
  task.cucumber_opts += %w[-f progress] unless ENV['TRAVIS']
  task.fork = false
end

desc 'generate connection diagram'
task :diagram do
  system 'dot connections.dot -Tpng > connections.png'
end

task default: %i[spec cucumber]
