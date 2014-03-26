require 'bundler'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'
Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new :spec do |task|
  task.pattern = FileList['spec/**/*_spec.rb']
  task.rspec_opts = %w[-f doc] if ENV['TRAVIS']
  task.verbose = false
end

Cucumber::Rake::Task.new :cucumber do |task|
  task.cucumber_opts = %w[--tags ~@wip]
  task.cucumber_opts += %w[-f progress] unless ENV['TRAVIS']
  task.fork = false
end

desc "generate connection diagram"
task :diagram do
  system "dot connections.dot -Tpng > connections.png"
end

task default: [:spec, :cucumber]
