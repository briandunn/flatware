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
        @jobs, @formatter = jobs, formatter
        options = {fail_fast: false}.merge options
        @fail_fast = options[:fail_fast]
        @socket = Flatware.socket(ZMQ::PULL, bind: endpoint)
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

      def checkpoint_handler
        @checkpoint_handler ||= CheckpointHandler.new(formatter, fail_fast?)
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

      def fireable
        @fireable ||= Fireable.new
      end
    end
  end
end
