require 'drb/drb'

module Flatware
  module Sink
    extend self

    def start_server(*args)
      Server.new(*args).start
    end

    attr_accessor :client

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
        trap 'INT' do
          puts "Interrupted!"
          formatter.summarize checkpoints
          summarize_remaining
          puts "\n\nCleaning up. Please wait...\n"
          Flatware.close!
          Process.waitall
          puts "thanks."
          exit 1
        end
        formatter.jobs jobs
        DRb.start_service(sink, self)
        DRb.thread.join
        Flatware.close
        !failures?
      end

      def ready(worker)
        job = queue.shift
        if job and not done?
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
        Flatware.log(:method_missing, name, *args)
        formatter.send(name, *args)
      end

      private

      def check_finished!
        if workers.empty? and done?
          DRb.stop_service
          formatter.summarize(checkpoints)
        end
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
        jobs.group_by.with_index do |_,i|
          i % worker_count
        end.values.map do |jobs|
          Job.new(jobs.map(&:id).flatten, jobs.first.args)
        end
      end
    end
  end
end
