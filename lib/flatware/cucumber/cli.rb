# frozen_string_literal: true

require 'flatware/cli'

module Flatware
  class CLI
    runner_options
    desc 'cucumber [FLATWARE_OPTS] [CUCUMBER_ARGS]', 'parallelizes cucumber with custom arguments'
    def cucumber(*args)
      config = Cucumber.configure args

      unless config.jobs.any?
        puts "Please create some feature files in the #{config.feature_dir} directory."
        exit 1
      end

      Flatware.verbose = options[:log]

      spawn_workers(runner: Cucumber)
      start_sink jobs: config.jobs, workers: workers, formatter: Flatware::Cucumber::Formatters::Console.new($stdout, $stderr)
    end
  end
end
