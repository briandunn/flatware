require 'flatware'
module Flatware
  module Sink
    extend self

    def start_server(*args)
      Server.new(*args).start
    end

    class Server
      attr_reader :sink, :dispatch, :poller, :workers, :checkpoints, :jobs, :formatter

      def initialize(jobs:, formatter:, dispatch:, sink:, worker_count: 0)
        @formatter = formatter
        @jobs = group_jobs(jobs, worker_count)
        @sink = Flatware.socket(ZMQ::PULL, bind: sink)
        @dispatch = Flatware.socket(ZMQ::REP, bind: dispatch)
        @poller = Poller.new(@sink, @dispatch)
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
        listen.tap do
          Flatware.close
        end
      end

      def listen
        que = jobs.dup
        poller.each do |socket|
          message, content = socket.recv

          case message
          when :ready
            workers << content
            job = que.shift
            if job and not done?
              dispatch.send job
            else
              workers.delete content
              dispatch.send 'seppuku'
            end
          when :checkpoint
            checkpoints << content
          when :finished
            completed_jobs << content
            formatter.finished content
          else
            formatter.send message, content
          end
          break if workers.empty? and done?
        end
        formatter.summarize(checkpoints)
        !failures?
      end

      private

      def failures?
        checkpoints.any?(&:failures?) || completed_jobs.any?(&:failed?)
      end

      def summarize_remaining
        return if remaining_work.empty?
        formatter.summarize_remaining remaining_work
      end

      def log(*args)
        Flatware.log *args
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
