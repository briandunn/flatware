# frozen_string_literal: true

require 'bundler'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

%w[flatware flatware-rspec flatware-cucumber].each do |gem_name|
  Bundler::GemHelper.install_tasks name: gem_name
end

RSpec::Core::RakeTask.new :spec do |task|
  task.pattern = FileList['spec/**/*_spec.rb']
  task.rspec_opts = %w[-f doc] if ENV['TRAVIS']
  task.verbose = false
end

RuboCop::RakeTask.new :lint

Cucumber::Rake::Task.new :cucumber do |task|
  task.cucumber_opts = ['--tags', 'not @wip']
  task.cucumber_opts += %w[-f progress] unless ENV['TRAVIS']
  task.fork = false
end

desc 'generate connection diagram'
task :diagram do
  system 'dot connections.dot -Tpng > connections.png'
end

task default: %i[lint spec cucumber]
