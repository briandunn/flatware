# frozen_string_literal: true

require 'flatware/cli'

module Flatware
  # cucumber thor command
  class CLI
    worker_option
    method_option(
      'sink-endpoint',
      type: :string,
      default: 'druby://localhost:8787'
    )
    desc(
      'cucumber [FLATWARE_OPTS] [CUCUMBER_ARGS]',
      'parallelizes cucumber with custom arguments'
    )
    def cucumber(*args)
      config = Cucumber.configure args

      ensure_jobs(config)

      Flatware.verbose = options[:log]
      sink = options['sink-endpoint']
      Worker.spawn(count: workers, runner: Cucumber, sink: sink)
      start_sink(
        jobs: config.jobs,
        workers: workers,
        formatter: Flatware::Cucumber::Formatters::Console.new($stdout, $stderr)
      )
    end

    private

    def ensure_jobs(config)
      return if config.jobs.any?

      abort(
        format(
          'Please create some feature files in the %<dir>s directory.',
          dir: config.feature_dir
        )
      )
    end
  end
end
