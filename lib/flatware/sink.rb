require 'drb/drb'
require 'set'
require 'flatware/sink/signal'

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
      attr_reader :checkpoints, :completed_jobs, :formatter, :jobs, :queue, :sink, :workers

      def initialize(jobs:, formatter:, sink:, worker_count: 0, **)
        @checkpoints = []
        @completed_jobs = []
        @formatter = formatter
        @jobs = group_jobs(jobs, worker_count).freeze
        @queue = @jobs.dup
        @sink = sink
        @workers = Set.new(worker_count.times.to_a)
      end

      def start
        @signal = Signal.listen(&method(:summarize_remaining))
        formatter.jobs jobs
        DRb.start_service(sink, self, verbose: Flatware.verbose?)
        DRb.thread.join
        !failures?
      end

      def ready(worker)
        job = queue.shift
        if job && !(remaining_work.empty? || interruped?)
          workers << worker
          job
        else
          workers.delete worker
          check_finished!
          Job.sentinel
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

      def interruped?
        @signal&.interruped?
      end

      def check_finished!
        return unless [workers, remaining_work].all?(&:empty?)

        DRb.stop_service
        summarize
      end

      def failures?
        checkpoints.any?(&:failures?) || completed_jobs.any?(&:failed?)
      end

      def summarize_remaining
        summarize
        return if remaining_work.empty?

        formatter.summarize_remaining remaining_work
      end

      def remaining_work
        jobs - completed_jobs
      end

      def summarize
        formatter.summarize(checkpoints)
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
