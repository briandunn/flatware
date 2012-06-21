require 'bundler'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'
Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new :spec do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

Cucumber::Rake::Task.new :cucumber do |task|
  task.cucumber_opts = %w[--tags ~@wip]
end

task :default => [:spec, :cucumber]
