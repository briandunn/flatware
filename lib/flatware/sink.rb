require 'flatware'
module Flatware
  module Sink
    extend self

    def start_server(*args)
      Server.new(*args).start
    end

    class Server
      attr_reader :socket

      def initialize(jobs, formatter, endpoint, options={})
        @jobs, @formatter, @completed_jobs = jobs, formatter, []
        @fail_fast = options[:fail_fast]
        @socket = Flatware.socket(ZMQ::PULL, bind: endpoint)
        @checkpoint_handler = CheckpointHandler.new(formatter, options[:fail_fast])
      end

      def start
        trap 'INT' do
          checkpoint_handler.summarize
          summarize_remaining
          exit 1
        end

        Flatware::Fireable::bind
        formatter.jobs jobs
        listen
      ensure
        Flatware::Fireable::kill
        Flatware.close
      end

      def listen
        until done?
          message, content = socket.recv
          case message
          when :checkpoint
            checkpoint_handler.handle! content
          when :finished
            completed_jobs << content
            formatter.finished content
          else
            formatter.send message, content
          end
        end
        checkpoint_handler.summarize
        !checkpoint_handler.had_failures?
      rescue Error => e
        raise unless e.message == "Interrupted system call"
      end

      private

      attr_reader :jobs, :formatter, :checkpoint_handler, :completed_jobs

      def summarize_remaining
        return if remaining_work.empty?
        formatter.summarize_remaining remaining_work
      end

      def log(*args)
        Flatware.log *args
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
