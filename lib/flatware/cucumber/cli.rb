# frozen_string_literal: true

require 'flatware/cli'

module Flatware
  # cucumber thor command
  class CLI
    worker_option
    method_option(
      'sink-endpoint',
      type: :string,
      default: 'drbunix:sink'
    )
    desc(
      'cucumber [FLATWARE_OPTS] [CUCUMBER_ARGS]',
      'parallelizes cucumber with custom arguments'
    )
    def cucumber(*args)
      jobs = load_jobs(args)

      formatter = Flatware::Cucumber::Formatters::Console.new($stdout, $stderr)

      Flatware.verbose = options[:log]

      spawn_count = worker_spawn_count(jobs)
      Worker.spawn(count: spawn_count, runner: Cucumber, sink: options['sink-endpoint'])
      start_sink(jobs: jobs, workers: spawn_count, formatter: formatter)
    end

    private

    def load_jobs(args)
      config = Cucumber.configure args
      return config.jobs if config.jobs.any?

      abort(
        format(
          'Please create some feature files in the %<dir>s directory.',
          dir: config.feature_dir
        )
      )
    end
  end
end
