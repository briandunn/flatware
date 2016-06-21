require 'thor'
require 'flatware/pids'
module Flatware
  class CLI < Thor

    def self.processors
      @processors ||= ProcessorInfo.count
    end

    def self.worker_option
      method_option :workers, aliases: "-w", type: :numeric, default: processors, desc: "Number of concurent processes to run"
    end

    class_option :log, aliases: "-l", type: :boolean, desc: "Print debug messages to $stderr"

    default_task :default
    worker_option
    desc "default [FLATWARE_OPTS]", "parallelizes cucumber with default arguments"
    def default(*)
      invoke :cucumber
    end

    worker_option
    method_option 'fail-fast', type: :boolean, default: false, desc: "Abort the run on first failure"
    method_option 'formatters', aliases: "-f", type: :array, default: %w[console], desc: "The formatters to use for output"
    method_option 'dispatch-endpoint', type: :string, default: 'ipc://dispatch'
    method_option 'sink-endpoint', type: :string, default: 'ipc://task'
    desc "[FLATWARE_OPTS] cucumber [CUCUMBER_ARGS]", "parallelizes cucumber with custom arguments"
    def cucumber(*)
      jobs = Cucumber.extract_jobs_from_args cucumber_args
      Flatware.verbose = options[:log]
      Worker.spawn workers, Cucumber, options['dispatch-endpoint'], options['sink-endpoint']
      formatter = Formatters.load_by_name(:cucumber, options['formatters'])
      start_sink jobs, formatter
    end

    worker_option
    desc "fan [COMMAND]", "executes the given job on all of the workers"
    def fan(*command)
      Flatware.verbose = options[:log]

      command = command.join(" ")
      puts "Running '#{command}' on #{workers} workers"

      workers.times do |i|
        fork do
          exec({"TEST_ENV_NUMBER" => i.to_s}, command)
        end
      end
      Process.waitall
    end


    desc "clear", "kills all flatware processes"
    def clear
      (Flatware.pids - [$$]).each do |pid|
        Process.kill 6, pid
      end
    end

    private

    def start_sink(jobs, formatter)
     $0 = 'flatware sink'
      Process.setpgrp
      passed = Sink.start_server jobs: jobs, formatter: formatter, sink: options['sink-endpoint'], dispatch: options['dispatch-endpoint'], fail_fast: options['fail-fast']
      Process.waitall
      exit passed ? 0 : 1
    end

    def cucumber_args
      if index = ARGV.index('cucumber')
        ARGV[index + 1..-1]
      else
        []
      end
    end

    def log(*args)
      Flatware.log(*args)
    end

    def workers
      options[:workers]
    end
  end
end
