require 'drb/drb'

module Flatware
  module Sink
    module_function

    def start_server(**args)
      Server.new(**args).start
    end

    def client
      @client
    end

    def client=(client)
      @client = client
    end

    class Server
      attr_reader :workers, :checkpoints, :jobs, :queue, :formatter, :sink

      def initialize(jobs:, formatter:, sink:, worker_count: 0, **)
        @sink = sink
        @formatter = formatter
        @jobs = group_jobs(jobs, worker_count)
        @queue = @jobs.dup
        @jobs.freeze

        @workers = Set.new(worker_count.times.to_a)
        @checkpoints = []
      end

      def start
        trap_interrupt
        formatter.jobs jobs
        DRb.start_service(sink, self)
        DRb.thread.join
        !failures?
      end

      def ready(worker)
        job = queue.shift
        if job && !done?
          workers << worker
          job
        else
          workers.delete worker
          check_finished!
          'seppuku'
        end
      end

      def checkpoint(checkpoint)
        checkpoints << checkpoint
      end

      def finished(job)
        completed_jobs << job
        formatter.finished(job)
        check_finished!
      end

      def method_missing(name, *args)
        super unless formatter.respond_to?(name)
        Flatware.log(name, *args)
        formatter.send(name, *args)
      end

      def respond_to_missing?(name, include_all)
        formatter.respond_to?(name, include_all)
      end

      private

      def trap_interrupt
        trap 'INT' do
          puts 'Interrupted!'
          formatter.summarize checkpoints
          summarize_remaining
          puts "\n\nCleaning up. Please wait...\n"
          Process.waitall
          puts 'thanks.'
          exit 1
        end
      end

      def check_finished!
        return unless workers.empty? && done?

        DRb.stop_service
        formatter.summarize(checkpoints)
      end

      def failures?
        checkpoints.any?(&:failures?) || completed_jobs.any?(&:failed?)
      end

      def summarize_remaining
        return if remaining_work.empty?

        formatter.summarize_remaining remaining_work
      end

      def completed_jobs
        @completed_jobs ||= []
      end

      def done?
        remaining_work.empty?
      end

      def remaining_work
        jobs - completed_jobs
      end

      def group_jobs(jobs, worker_count)
        return jobs unless worker_count > 1

        jobs
          .group_by
          .with_index { |_, i| i % worker_count }
          .values
          .map do |job_group|
          Job.new(job_group.map(&:id).flatten, jobs.first.args)
        end
      end
    end
  end
end
