require 'flatware'
module Flatware
  module Sink
    extend self

    def start_server(*args)
      Server.new(*args).start
    end

    class Server
      attr_reader :sink, :dispatch, :poller, :workers

      def initialize(jobs:, formatter:, dispatch:, sink:, fail_fast: false, worker_count: 0)
        @jobs, @formatter, @fail_fast = jobs, formatter, fail_fast
        @sink = Flatware.socket(ZMQ::PULL, bind: sink)
        @dispatch = Flatware.socket(ZMQ::REP, bind: dispatch)
        @poller = Poller.new(@sink, @dispatch)
        @workers = Set.new(worker_count.times.to_a)
      end

      def start
        trap 'INT' do
          puts "Interrupted!"
          checkpoint_handler.summarize
          summarize_remaining
          exit 1
        end
        formatter.jobs jobs
        listen
      ensure
        Flatware.close
      end

      def checkpoint_handler
        @checkpoint_handler ||= CheckpointHandler.new(formatter, fail_fast?)
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
            checkpoint_handler.handle! content
          when :finished
            completed_jobs << content
            formatter.finished content
          else
            formatter.send message, content
          end
          break if workers.empty? and done?
        end
        checkpoint_handler.summarize
        !failures?
      end

      private

      def failures?
        checkpoint_handler.had_failures? || completed_jobs.any?(&:failed?)
      end

      def fail_fast?
        @fail_fast
      end

      attr_reader :jobs, :formatter

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
        remaining_work.empty? || checkpoint_handler.done?
      end

      def remaining_work
        jobs - completed_jobs
      end
    end
  end
end
