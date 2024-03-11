require 'drb/drb'
require 'set'

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
      attr_reader :checkpoints, :completed_jobs, :in_progress_jobs, :formatter, :jobs, :queue, :sink, :worker_manager

      def initialize(jobs:, formatter:, sink:, worker_manager:, **)
        @checkpoints = []
        @completed_jobs = []
        @formatter = formatter
        @jobs = group_jobs(jobs, worker_manager.count).freeze
        @queue = @jobs.dup
        @in_progress_jobs = {}
        @sink = sink
        @worker_manager = worker_manager
      end

      def start
        trap_interrupt
        formatter.jobs jobs
        worker_manager.spawn
        DRb.start_service(sink, self, verbose: Flatware.verbose?)
        DRb.thread.join
        worker_manager.stop
        !failures?
      end

      def ready(worker)
        job = in_progress_jobs[worker] || queue.shift
        if job && !(remaining_work.empty? || interrupted?)
          worker_manager.register worker
          in_progress_jobs[worker] = job
          job
        else
          worker_manager.delete worker
          check_finished!
          Job.sentinel
        end
      end

      def checkpoint(checkpoint)
        checkpoints << checkpoint
      end

      def finished(job)
        completed_jobs << job
        in_progress_jobs.delete(job.worker)
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
        Thread.main[:signals] = Queue.new

        Thread.new(&method(:handle_interrupt))

        trap 'INT' do
          Thread.main[:signals] << :int
        end
      end

      def handle_interrupt
        Thread.main[:signals].pop
        puts 'Interrupted!'
        summarize_remaining
        puts "\n\nCleaning up. Please wait...\n"
        Process.waitall
        puts 'done.'
        abort
      end

      def interrupted?
        signals = Thread.main[:signals]
        signals && !signals.empty?
      end

      def check_finished!
        return unless [worker_manager.workers, remaining_work].all?(&:empty?)

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
