# frozen_string_literal: true

require 'thor'
require 'flatware/pids'
module Flatware
  class CLI < Thor
    def self.processors
      @processors ||= ProcessorInfo.count
    end

    def self.worker_option
      method_option :workers, aliases: '-w', type: :numeric, default: processors, desc: 'Number of concurent processes to run'
    end

    class_option :log, aliases: '-l', type: :boolean, desc: 'Print debug messages to $stderr'

    worker_option
    desc 'fan [COMMAND]', 'executes the given job on all of the workers'
    def fan(*command)
      Flatware.verbose = options[:log]

      command = command.join(' ')
      puts "Running '#{command}' on #{workers} workers"

      workers.times do |i|
        fork do
          exec({ 'TEST_ENV_NUMBER' => i.to_s }, command)
        end
      end
      Process.waitall
    end

    desc 'clear', 'kills all flatware processes'
    def clear
      (Flatware.pids - [$PROCESS_ID]).each do |pid|
        Process.kill 6, pid
      end
    end

    private

    def start_sink(jobs:, workers:, formatter:)
      $0 = 'flatware sink'
      Process.setpgrp
      passed = Sink.start_server(jobs: jobs, formatter: Flatware::Broadcaster.new([formatter]), sink: options['sink-endpoint'], dispatch: options['dispatch-endpoint'], worker_count: workers)
      exit passed ? 0 : 1
    end

    def log(*args)
      Flatware.log(*args)
    end

    def workers
      options[:workers]
    end
  end
end

flatware_gems = %w[flatware-rspec flatware-cucumber]

loaded_flatware_gem_count = flatware_gems.map do |flatware_gem|
  begin
    require flatware_gem
  rescue LoadError
    nil
  end
end.compact.size

if loaded_flatware_gem_count.zero?
  warn(
    format(<<~MESSAGE, gem_list: flatware_gems.join(' or ')))
      The flatware gem is a dependency of flatware runners for rspec and cucumber.
      Install %<gem_list>s for more usefull commands.
    MESSAGE

end
