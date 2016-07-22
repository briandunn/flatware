require 'flatware/cli'

module Flatware
  class CLI
    worker_option
    method_option 'dispatch-endpoint', type: :string, default: 'ipc://dispatch'
    method_option 'sink-endpoint', type: :string, default: 'ipc://task'
    desc "rspec [FLATWARE_OPTS]", "parallelizes rspec"
    def rspec(*rspec_args)
      jobs = RSpec.extract_jobs_from_args rspec_args, workers: workers
      Flatware.verbose = options[:log]
      Worker.spawn count: workers, runner: RSpec, dispatch: options['dispatch-endpoint'], sink: options['sink-endpoint']
      start_sink jobs: jobs, workers: workers, formatter: Flatware::RSpec::Formatters::Console.new($stdout, $stderr)
    end
  end
end
