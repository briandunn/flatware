require 'flatware/cli'

module Flatware
  class CLI
    worker_option
    method_option 'dispatch-endpoint', type: :string, default: 'ipc://dispatch'
    method_option 'sink-endpoint', type: :string, default: 'druby://localhost:8787'
    desc "cucumber [FLATWARE_OPTS] [CUCUMBER_ARGS]", "parallelizes cucumber with custom arguments"
    def cucumber(*args)
      config = Cucumber.configure args

      unless config.jobs.any?
        puts "Please create some feature files in the #{config.feature_dir} directory."
        exit 1
      end

      Flatware.verbose = options[:log]
      Worker.spawn count: workers, runner: Cucumber, dispatch: options['dispatch-endpoint'], sink: options['sink-endpoint']
      start_sink jobs: config.jobs, workers: workers, formatter: Flatware::Cucumber::Formatters::Console.new($stdout, $stderr)
    end
  end
end
